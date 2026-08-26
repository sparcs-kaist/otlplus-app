import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

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

class _ThrowingPrefsStore extends SharedPreferencesStorePlatform {
  @override
  Future<bool> clear() async {
    throw StateError('preferences clear failed');
  }

  @override
  Future<Map<String, Object>> getAll() async => <String, Object>{};

  @override
  Future<bool> remove(String key) async {
    throw StateError('preferences remove failed');
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    throw StateError('preferences write failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesStorePlatform originalStore;

  setUp(() {
    originalStore = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
    SharedPreferences.resetStatic();
  });

  tearDown(() {
    SharedPreferencesStorePlatform.instance = originalStore;
    SharedPreferences.resetStatic();
  });

  test('setter persists value through guarded helper', () async {
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    final model = SettingsModel(forTest: true, telemetry: telemetry);

    await runZonedGuarded<Future<void>>(
      () async {
        model.setSendCrashlytics(false);
        await Future<void>.delayed(Duration.zero);
      },
      (error, stackTrace) {
        escapedErrors.add(error);
      },
    );

    SharedPreferences.resetStatic();
    final preferences = await SharedPreferences.getInstance();

    expect(preferences.getBool('sendCrashlytics'), isFalse);
    expect(model.getSendCrashlytics(), isFalse);
    expect(telemetry.nonFatals, isEmpty);
    expect(escapedErrors, isEmpty);
  });

  test('persist failure records non fatal and does not escape zone', () async {
    SharedPreferencesStorePlatform.instance = _ThrowingPrefsStore();
    SharedPreferences.resetStatic();
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    final model = SettingsModel(forTest: true, telemetry: telemetry);

    await runZonedGuarded<Future<void>>(
      () async {
        model.setSendCrashlytics(false);
        await Future<void>.delayed(Duration.zero);
      },
      (error, stackTrace) {
        escapedErrors.add(error);
      },
    );

    expect(escapedErrors, isEmpty);
    expect(telemetry.nonFatals, hasLength(1));
    expect(telemetry.nonFatals.single.operation, 'persist_send_crashlytics');
    expect(model.getSendCrashlytics(), isFalse);
  });

  test('all seven persisted setters route through guarded persist', () async {
    SharedPreferencesStorePlatform.instance = _ThrowingPrefsStore();
    SharedPreferences.resetStatic();
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    final model = SettingsModel(
      forTest: true,
      telemetry: telemetry,
      subscribeToTopic: (_) async {},
      unsubscribeFromTopic: (_) async {},
    );

    await runZonedGuarded<Future<void>>(
      () async {
        model.setSendCrashlytics(false);
        model.setSendCrashlyticsAnonymously(true);
        model.setShowsChannelTalkButton(false);
        await model.setSendAlarm(false);
        await Future<void>.delayed(Duration.zero);
      },
      (error, stackTrace) {
        escapedErrors.add(error);
      },
    );

    expect(escapedErrors, isEmpty);
    expect(telemetry.nonFatals, hasLength(7));
    expect(
      telemetry.nonFatals.map((record) => record.operation).toSet(),
      <String>{
        'persist_send_crashlytics',
        'persist_send_crashlytics_anonymously',
        'persist_shows_channel_talk_button',
        'persist_send_alarm',
        'persist_promotion_alarm',
        'persist_information_alarm',
        'persist_subject_suggestion_alarm',
      },
    );
  });
}
