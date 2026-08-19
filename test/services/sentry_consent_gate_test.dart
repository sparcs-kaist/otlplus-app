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

  test('disables automatic Dart telemetry outside consent hooks', () {
    final gate = SentryConsentGate();
    final options = SentryOptions();

    gate.configure(options);

    expect(options.captureFailedRequests, isFalse);
    expect(options.recordHttpBreadcrumbs, isFalse);
    expect(options.sendClientReports, isFalse);
    expect(options.enableMetrics, isFalse);
    expect(options.enableLogs, isFalse);
    expect(options.tracePropagationTargets, isEmpty);
  });
}
