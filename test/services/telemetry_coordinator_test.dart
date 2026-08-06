import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';

class _FakeAnalyticsClient implements AnalyticsClient {
  final List<String> operations = <String>[];
  var disableCount = 0;
  var enableCount = 0;
  var initializeCount = 0;
  var resetCount = 0;

  @override
  Future<void> disable() async {
    disableCount++;
    operations.add('disable');
  }

  @override
  Future<void> enable() async {
    enableCount++;
    operations.add('enable');
  }

  @override
  Future<void> initialize() async => initializeCount++;

  @override
  Future<void> reset() async {
    resetCount++;
    operations.add('reset');
  }
}

class _FakeCrashReportingClient implements CrashReportingClient {
  final List<String> identifiers = <String>[];
  final List<bool> collectionStates = <bool>[];
  final List<String> operations = <String>[];
  final List<String> reportedReasons = <String>[];
  var deleteUnsentReportsCount = 0;

  @override
  Future<void> deleteUnsentReports() async {
    deleteUnsentReportsCount++;
    operations.add('delete');
  }

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
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionStates.add(enabled);
    operations.add(enabled ? 'enable_crashlytics' : 'disable_crashlytics');
  }

  @override
  Future<void> setUserIdentifier(String identifier) async {
    identifiers.add(identifier);
    operations.add('identifier:$identifier');
  }
}

void main() {
  test('initializes analytics and reports sanitized nonfatal errors', () async {
    final analytics = _FakeAnalyticsClient();
    final crashReporting = _FakeCrashReportingClient();
    final coordinator = TelemetryCoordinator(
      analytics: analytics,
      crashReporting: crashReporting,
    );

    await coordinator.initialize();
    await coordinator.recordNonFatal(
      Exception('secret response body'),
      StackTrace.current,
      operation: 'load_courses',
    );

    expect(analytics.initializeCount, 1);
    expect(crashReporting.reportedReasons, <String>['load_courses']);
  });

  test('does not synchronize a state before settings are ready', () async {
    final analytics = _FakeAnalyticsClient();
    final crashReporting = _FakeCrashReportingClient();
    final coordinator = TelemetryCoordinator(
      analytics: analytics,
      crashReporting: crashReporting,
    );

    await coordinator.synchronize(
      const TelemetryState(
        isReady: false,
        crashlyticsEnabled: true,
        crashlyticsAnonymous: false,
        analyticsEnabled: true,
        userIdentifier: '42',
      ),
    );

    expect(crashReporting.operations, isEmpty);
    expect(analytics.operations, isEmpty);
  });

  test('synchronizes each distinct ready telemetry state once', () async {
    final analytics = _FakeAnalyticsClient();
    final crashReporting = _FakeCrashReportingClient();
    final coordinator = TelemetryCoordinator(
      analytics: analytics,
      crashReporting: crashReporting,
    );
    const state = TelemetryState(
      isReady: true,
      crashlyticsEnabled: true,
      crashlyticsAnonymous: false,
      analyticsEnabled: true,
      userIdentifier: '42',
    );

    await coordinator.synchronize(state);
    await coordinator.synchronize(state);

    expect(crashReporting.collectionStates, <bool>[true]);
    expect(crashReporting.identifiers, <String>['42']);
    expect(analytics.enableCount, 1);
    expect(
      crashReporting.operations,
      <String>['identifier:42', 'enable_crashlytics'],
    );
  });

  test(
    'clears identifiers and disables analytics after consent is withdrawn',
    () async {
    final analytics = _FakeAnalyticsClient();
    final crashReporting = _FakeCrashReportingClient();
    final coordinator = TelemetryCoordinator(
      analytics: analytics,
      crashReporting: crashReporting,
    );

    await coordinator.synchronize(
      const TelemetryState(
        isReady: true,
        crashlyticsEnabled: false,
        crashlyticsAnonymous: false,
        analyticsEnabled: false,
        userIdentifier: '42',
      ),
    );

    expect(crashReporting.collectionStates, <bool>[false]);
    expect(crashReporting.identifiers, <String>['']);
    expect(crashReporting.deleteUnsentReportsCount, 1);
    expect(analytics.resetCount, 1);
    expect(analytics.disableCount, 1);
    expect(crashReporting.operations, <String>[
      'disable_crashlytics',
      'identifier:',
      'delete',
    ]);
    expect(analytics.operations, <String>['disable', 'reset']);
    },
  );
}
