import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/services/sentry_consent_gate.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('drops Sentry telemetry unless crash reporting is enabled', () async {
    final gate = SentryConsentGate();
    final event = SentryEvent();
    final breadcrumb = Breadcrumb(message: 'opened app');

    expect(gate.filterEvent(event), isNull);
    expect(gate.filterBreadcrumb(breadcrumb), isNull);
    expect(gate.filterBreadcrumb(null), isNull);

    await gate.setEnabled(true);

    expect(gate.filterEvent(event), same(event));
    expect(gate.filterBreadcrumb(breadcrumb), same(breadcrumb));

    await gate.setEnabled(false);

    expect(gate.filterEvent(event), isNull);
    expect(gate.filterBreadcrumb(breadcrumb), isNull);
  });

  test('disables native collection that bypasses Dart consent hooks', () {
    final gate = SentryConsentGate();
    final options = SentryFlutterOptions();

    gate.configure(options);

    expect(options.enableNativeCrashHandling, isFalse);
    expect(options.enableAutoSessionTracking, isFalse);
    expect(options.anrEnabled, isFalse);
    expect(options.enableAutoNativeBreadcrumbs, isFalse);
    expect(options.enableWatchdogTerminationTracking, isFalse);
    expect(options.enableAppHangTracking, isFalse);
    expect(options.enableUserInteractionBreadcrumbs, isFalse);
    expect(options.enableUserInteractionTracing, isFalse);
    expect(options.enableAutoPerformanceTracing, isFalse);
    expect(options.enableFramesTracking, isFalse);
    expect(options.enableNativeTraceSync, isFalse);
    expect(options.enableNdkScopeSync, isFalse);
    expect(options.maxCacheItems, 0);
  });
}
