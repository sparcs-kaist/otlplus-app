import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';

const _channelTalkChannel = MethodChannel('channel_talk_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channelTalkChannel, null);
  });

  test('records non-fatal when channeltalk update fails', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    final model = _LoadedInfoModel(telemetry: telemetry);

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
    var updateUserCallCount = 0;
    final model = _LoadedInfoModel(telemetry: telemetry);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channelTalkChannel, (call) async {
          if (call.method == 'isBooted') return false;
          if (call.method == 'updateUser') updateUserCallCount++;
          return null;
        });

    await model.getInfo();
    await Future<void>.delayed(Duration.zero);

    expect(updateUserCallCount, 0);
    expect(telemetry.nonFatals, isEmpty);
  });

  test('updates channeltalk user when booted', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final updateUserArguments = <Object?>[];
    final model = _LoadedInfoModel(telemetry: telemetry);

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
  _LoadedInfoModel({required TelemetryCoordinator telemetry})
    : super(forTest: true, telemetry: telemetry);

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
