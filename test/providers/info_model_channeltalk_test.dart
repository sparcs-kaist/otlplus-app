import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/services/channel_talk_readiness.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';

const _channelTalkChannel = MethodChannel('channel_talk_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channelTalkChannel, null);
  });

  test(
    'records non-fatal when channeltalk readiness resolves unavailable',
    () async {
      final telemetry = _RecordingTelemetryCoordinator();
      final readiness = ChannelTalkReadiness()..markUnavailable();
      var updateUserCallCount = 0;
      final model = _LoadedInfoModel(
        telemetry: telemetry,
        channelTalkReadiness: readiness,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channelTalkChannel, (call) async {
            if (call.method == 'isBooted') return true;
            if (call.method == 'updateUser') updateUserCallCount += 1;
            return true;
          });

      await model.getInfo();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(updateUserCallCount, 0);
      expect(telemetry.nonFatals, hasLength(1));
      expect(telemetry.nonFatals.single.operation, 'update_channeltalk_user');
    },
  );

  test(
    'syncs channeltalk user when boot completes after the retry budget would have expired',
    () async {
      final telemetry = _RecordingTelemetryCoordinator();
      final readiness = ChannelTalkReadiness();
      var updateUserCallCount = 0;
      final model = _LoadedInfoModel(
        telemetry: telemetry,
        channelTalkReadiness: readiness,
        channelTalkReadyTimeout: const Duration(milliseconds: 100),
      );
      addTearDown(readiness.markUnavailable);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channelTalkChannel, (call) async {
            if (call.method == 'updateUser') updateUserCallCount += 1;
            return true;
          });

      await model.getInfo();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      readiness.markBooted();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(updateUserCallCount, 1);
      expect(telemetry.nonFatals, isEmpty);
    },
  );

  test(
    'applies only the latest user when the first update is still in flight',
    () async {
      final telemetry = _RecordingTelemetryCoordinator();
      final firstUpdateStarted = Completer<void>();
      final finishFirstUpdate = Completer<void>();
      final appliedUserNames = <String>[];
      final readiness = ChannelTalkReadiness()..markBooted();
      final model = _SequencedInfoModel(
        telemetry: telemetry,
        users: <User>[_testUser(1, 'First'), _testUser(2, 'Second')],
        channelTalkReadiness: readiness,
      );
      addTearDown(() {
        if (!finishFirstUpdate.isCompleted) finishFirstUpdate.complete();
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channelTalkChannel, (call) async {
            if (call.method == 'isBooted') return true;
            if (call.method == 'updateUser') {
              final arguments = call.arguments as Map<Object?, Object?>;
              final name = arguments['name']! as String;
              if (name == 'First User') {
                firstUpdateStarted.complete();
                await finishFirstUpdate.future;
              }
              appliedUserNames.add(name);
            }
            return true;
          });

      await model.getInfo();
      await firstUpdateStarted.future;
      await model.reload();
      await Future<void>.delayed(Duration.zero);
      finishFirstUpdate.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(appliedUserNames, isNotEmpty);
      expect(appliedUserNames.last, 'Second User');
      expect(telemetry.nonFatals, isEmpty);
    },
  );

  test('records non-fatal when channeltalk update fails', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    final readiness = ChannelTalkReadiness()..markBooted();
    final model = _LoadedInfoModel(
      telemetry: telemetry,
      channelTalkReadiness: readiness,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channelTalkChannel, (call) async {
          if (call.method == 'isBooted') return true;
          if (call.method == 'updateUser') {
            throw PlatformException(code: 'updateUser');
          }
          return null;
        });

    await runZonedGuarded<Future<void>>(() async {
      await model.getInfo();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }, (error, stackTrace) => escapedErrors.add(error));

    expect(escapedErrors, isEmpty);
    expect(telemetry.nonFatals, hasLength(1));
    expect(telemetry.nonFatals.single.operation, 'update_channeltalk_user');
  });

  test('skips update user when channeltalk is not booted', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final readiness = ChannelTalkReadiness()..markUnavailable();
    var updateUserCallCount = 0;
    final model = _LoadedInfoModel(
      telemetry: telemetry,
      channelTalkReadiness: readiness,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channelTalkChannel, (call) async {
          if (call.method == 'updateUser') updateUserCallCount++;
          return null;
        });

    await model.getInfo();
    await Future<void>.delayed(Duration.zero);

    expect(updateUserCallCount, 0);
    expect(telemetry.nonFatals, hasLength(1));
  });

  test('waits for channeltalk readiness before updating the user', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final readiness = ChannelTalkReadiness();
    var updateUserCallCount = 0;
    final model = _LoadedInfoModel(
      telemetry: telemetry,
      channelTalkReadiness: readiness,
      channelTalkReadyTimeout: const Duration(milliseconds: 100),
    );
    addTearDown(readiness.markUnavailable);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channelTalkChannel, (call) async {
          if (call.method == 'updateUser') updateUserCallCount += 1;
          return true;
        });

    await model.getInfo();
    await Future<void>.delayed(Duration.zero);
    expect(updateUserCallCount, 0);

    readiness.markBooted();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(updateUserCallCount, 1);
    expect(telemetry.nonFatals, isEmpty);
  });

  test('records non-fatal when channeltalk never boots', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final readiness = ChannelTalkReadiness();
    final model = _LoadedInfoModel(
      telemetry: telemetry,
      channelTalkReadiness: readiness,
      channelTalkReadyTimeout: const Duration(milliseconds: 5),
    );
    addTearDown(readiness.markUnavailable);

    await model.getInfo();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(telemetry.nonFatals, hasLength(1));
    expect(telemetry.nonFatals.single.operation, 'update_channeltalk_user');
  });

  test('applies only the latest user when updates overlap', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final readiness = ChannelTalkReadiness();
    final updatedUserNames = <String>[];
    final model = _SequencedInfoModel(
      telemetry: telemetry,
      users: <User>[_testUser(1, 'First'), _testUser(2, 'Second')],
      channelTalkReadiness: readiness,
      channelTalkReadyTimeout: const Duration(milliseconds: 100),
    );
    addTearDown(readiness.markUnavailable);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channelTalkChannel, (call) async {
          if (call.method == 'updateUser') {
            final arguments = call.arguments as Map<Object?, Object?>;
            updatedUserNames.add(arguments['name']! as String);
          }
          return true;
        });

    await model.getInfo();
    await model.reload();
    readiness.markBooted();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(updatedUserNames, <String>['Second User']);
    expect(telemetry.nonFatals, isEmpty);
  });

  test('updates channeltalk user when booted', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final updateUserArguments = <Object?>[];
    final readiness = ChannelTalkReadiness()..markBooted();
    final model = _LoadedInfoModel(
      telemetry: telemetry,
      channelTalkReadiness: readiness,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channelTalkChannel, (call) async {
          if (call.method == 'isBooted') return true;
          if (call.method == 'updateUser') {
            updateUserArguments.add(call.arguments);
            return true;
          }
          return null;
        });

    await model.getInfo();
    await Future<void>.delayed(Duration.zero);

    expect(updateUserArguments, hasLength(1));
    expect(updateUserArguments.single, <String, dynamic>{
      'name': 'Test User',
      'email': 'test@example.com',
      'customAttributes': <String, dynamic>{'id': 42, 'studentId': '20260001'},
    });
    expect(telemetry.nonFatals, isEmpty);
  });
}

class _LoadedInfoModel extends InfoModel {
  _LoadedInfoModel({
    required TelemetryCoordinator telemetry,
    ChannelTalkReadiness? channelTalkReadiness,
    Duration channelTalkReadyTimeout = const Duration(seconds: 30),
  }) : super(
         infoRepository: InfoRepository(Dio()),
         forTest: true,
         telemetry: telemetry,
         channelTalkReadiness: channelTalkReadiness,
         channelTalkReadyTimeout: channelTalkReadyTimeout,
       );

  @override
  Future<List<Semester>> getSemesters() async => <Semester>[
    Semester(
      year: 2026,
      semester: 3,
      beginning: DateTime(2026, 8, 1),
      end: DateTime(2026, 12, 31),
    ),
  ];

  @override
  Future<User> getUser() async => User(
    id: 42,
    email: 'test@example.com',
    studentId: '20260001',
    firstName: 'Test',
    lastName: 'User',
    majors: const [],
    departments: const [],
    myTimetableLectures: const [],
    reviewWritableLectures: const [],
    reviews: const [],
  );

  @override
  Map<String, dynamic>? getCurrentSchedule() => null;
}

class _SequencedInfoModel extends InfoModel {
  _SequencedInfoModel({
    required TelemetryCoordinator telemetry,
    required List<User> users,
    ChannelTalkReadiness? channelTalkReadiness,
    Duration channelTalkReadyTimeout = const Duration(seconds: 30),
  }) : _users = users,
       super(
         infoRepository: InfoRepository(Dio()),
         forTest: true,
         telemetry: telemetry,
         channelTalkReadiness: channelTalkReadiness,
         channelTalkReadyTimeout: channelTalkReadyTimeout,
       );

  final List<User> _users;
  var _userIndex = 0;

  @override
  Future<List<Semester>> getSemesters() async => <Semester>[
    Semester(
      year: 2026,
      semester: 3,
      beginning: DateTime(2026, 8, 1),
      end: DateTime(2026, 12, 31),
    ),
  ];

  @override
  Future<User> getUser() async => _users[_userIndex++];

  @override
  Map<String, dynamic>? getCurrentSchedule() => null;
}

User _testUser(int id, String firstName) {
  return User(
    id: id,
    email: '$firstName@example.com',
    studentId: '2026000$id',
    firstName: firstName,
    lastName: 'User',
    majors: const [],
    departments: const [],
    myTimetableLectures: const [],
    reviewWritableLectures: const [],
    reviews: const [],
  );
}

class _RecordedNonFatal {
  const _RecordedNonFatal(this.error, this.stackTrace, this.operation);

  final Object error;
  final StackTrace stackTrace;
  final String operation;
}

class _RecordingTelemetryCoordinator extends TelemetryCoordinator {
  _RecordingTelemetryCoordinator()
    : super(
        analytics: _NoOpAnalyticsClient(),
        crashReporting: _NoOpCrashReportingClient(),
      );

  final List<_RecordedNonFatal> nonFatals = <_RecordedNonFatal>[];

  @override
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) async {
    nonFatals.add(_RecordedNonFatal(error, stackTrace, operation));
  }
}

class _NoOpAnalyticsClient implements AnalyticsClient {
  @override
  Future<void> capture(String eventName) async {}

  @override
  Future<void> identify(String distinctId) async {}

  @override
  Future<void> disable() async {}

  @override
  Future<void> enable() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> reset() async {}
}

class _NoOpCrashReportingClient implements CrashReportingClient {
  @override
  Future<void> deleteUnsentReports() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
    required String reason,
  }) async {}

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserIdentifier(String identifier) async {}
}
