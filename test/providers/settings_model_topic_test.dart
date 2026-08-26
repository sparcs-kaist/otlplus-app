import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopAnalyticsClient implements AnalyticsClient {
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

class _NoopCrashReportingClient implements CrashReportingClient {
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

class _RecordedNonFatal {
  const _RecordedNonFatal(this.error, this.operation);

  final Object error;
  final String operation;
}

class _RecordingTelemetryCoordinator extends TelemetryCoordinator {
  _RecordingTelemetryCoordinator()
    : super(
        analytics: _NoopAnalyticsClient(),
        crashReporting: _NoopCrashReportingClient(),
      );

  final List<_RecordedNonFatal> nonFatals = <_RecordedNonFatal>[];

  @override
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) async {
    nonFatals.add(_RecordedNonFatal(error, operation));
  }
}

FirebaseException _offlineMessagingError() {
  return FirebaseException(
    plugin: 'firebase_messaging',
    code: 'unknown',
    message: 'network connection lost',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('records non-fatal when channel button update fails', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    final model = SettingsModel(
      forTest: true,
      telemetry: telemetry,
      showChannelButton: () => Future<void>.error(StateError('show failed')),
      hideChannelButton: () => Future<void>.error(StateError('hide failed')),
      subscribeToTopic: (_) async {},
      unsubscribeFromTopic: (_) async {},
    );

    await runZonedGuarded<Future<void>>(
      () async {
        await model.applyChannelButtonVisibility(false);
      },
      (error, stackTrace) {
        escapedErrors.add(error);
      },
    );

    expect(escapedErrors, isEmpty);
    expect(telemetry.nonFatals, hasLength(1));
    expect(
      telemetry.nonFatals.single.operation,
      'update_channeltalk_channel_button',
    );
  });

  test(
    'records non-fatal instead of leaking zone error when topic subscribe fails',
    () async {
      final telemetry = _RecordingTelemetryCoordinator();
      final escapedErrors = <Object>[];
      final model = SettingsModel(
        forTest: true,
        telemetry: telemetry,
        subscribeToTopic: (_) => Future<void>.error(_offlineMessagingError()),
        unsubscribeFromTopic: (_) async {},
      );

      await runZonedGuarded<Future<void>>(
        () async {
          model.setPromotionAlarm(true);
          await Future<void>.delayed(Duration.zero);
        },
        (error, stackTrace) {
          escapedErrors.add(error);
        },
      );

      expect(escapedErrors, isEmpty);
      expect(telemetry.nonFatals, hasLength(1));
      expect(telemetry.nonFatals.single.operation, 'subscribe_promotion');
    },
  );

  test('clearAllValues completes even when every unsubscribe fails', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final unsubscribedTopics = <String>[];
    final model = SettingsModel(
      forTest: true,
      telemetry: telemetry,
      subscribeToTopic: (_) async {},
      unsubscribeFromTopic: (topic) {
        unsubscribedTopics.add(topic);
        return Future<void>.error(_offlineMessagingError());
      },
    );

    await expectLater(model.clearAllValues(), completes);

    expect(unsubscribedTopics, <String>[
      'promotion',
      'information',
      'subject_suggestion',
    ]);
    expect(telemetry.nonFatals, hasLength(3));
  });

  test('subscribes to expected topics when settings enabled', () async {
    final subscribedTopics = <String>[];
    final model = SettingsModel(
      forTest: true,
      subscribeToTopic: (topic) async {
        subscribedTopics.add(topic);
      },
      unsubscribeFromTopic: (_) async {},
    );

    model.setPromotionAlarm(true);
    model.setInformationAlarm(true);
    model.setSubjectSuggestionAlarm(true);
    await Future<void>.delayed(Duration.zero);

    expect(subscribedTopics, <String>[
      'promotion',
      'information',
      'subject_suggestion',
    ]);
  });

  test('unsubscribes from expected topics when settings disabled', () async {
    final unsubscribedTopics = <String>[];
    final model = SettingsModel(
      forTest: true,
      subscribeToTopic: (_) async {},
      unsubscribeFromTopic: (topic) async {
        unsubscribedTopics.add(topic);
      },
    );

    model.setPromotionAlarm(false);
    model.setInformationAlarm(false);
    model.setSubjectSuggestionAlarm(false);
    await Future<void>.delayed(Duration.zero);

    expect(unsubscribedTopics, <String>[
      'promotion',
      'information',
      'subject_suggestion',
    ]);
  });
}
