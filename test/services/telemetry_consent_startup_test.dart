import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reports startup non-fatals when stored crash reporting consent is enabled',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'sendCrashlytics': true,
      });
      final crashReporting = _RecordingCrashReportingClient();
      final coordinator = TelemetryCoordinator(
        analytics: _NoOpAnalyticsClient(),
        crashReporting: crashReporting,
      );

      final storedConsent = await SettingsModel.loadCrashReportingEnabled();
      expect(storedConsent, isTrue);

      await coordinator.initialize(crashReportingEnabled: storedConsent);
      await coordinator.recordNonFatal(
        StateError('optional bootstrap failed'),
        StackTrace.current,
        operation: 'optional_bootstrap',
      );

      expect(crashReporting.reportedReasons, <String>['optional_bootstrap']);
    },
  );

  test('does not report startup non-fatals when consent is declined', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sendCrashlytics': false,
    });
    final crashReporting = _RecordingCrashReportingClient();
    final coordinator = TelemetryCoordinator(
      analytics: _NoOpAnalyticsClient(),
      crashReporting: crashReporting,
    );

    final storedConsent = await SettingsModel.loadCrashReportingEnabled();
    expect(storedConsent, isFalse);

    await coordinator.initialize(crashReportingEnabled: storedConsent);
    await coordinator.recordNonFatal(
      StateError('optional bootstrap failed'),
      StackTrace.current,
      operation: 'optional_bootstrap',
    );

    expect(crashReporting.reportedReasons, isEmpty);
  });
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

class _RecordingCrashReportingClient implements CrashReportingClient {
  final List<String> reportedReasons = <String>[];

  @override
  Future<void> deleteUnsentReports() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
    required String reason,
  }) async {
    reportedReasons.add(reason);
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserIdentifier(String identifier) async {}
}
