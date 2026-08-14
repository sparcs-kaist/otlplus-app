import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/services/sentry_consent_gate.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('drops Sentry telemetry until crash reporting is enabled', () {
    final gate = SentryConsentGate();
    final event = SentryEvent();
    final breadcrumb = Breadcrumb(message: 'opened app');

    expect(gate.filterEvent(event), isNull);
    expect(gate.filterBreadcrumb(breadcrumb), isNull);

    gate.setEnabled(true);

    expect(gate.filterEvent(event), same(event));
    expect(gate.filterBreadcrumb(breadcrumb), same(breadcrumb));
  });
}
