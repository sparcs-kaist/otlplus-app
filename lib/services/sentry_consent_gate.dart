import 'package:sentry_flutter/sentry_flutter.dart';

/// Drops Sentry telemetry until crash reporting is enabled in app settings.
class SentryConsentGate {
  bool _isEnabled = false;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  SentryEvent? filterEvent(SentryEvent event) => _isEnabled ? event : null;

  SentryTransaction? filterTransaction(SentryTransaction transaction) =>
      _isEnabled ? transaction : null;

  Breadcrumb? filterBreadcrumb(Breadcrumb breadcrumb) =>
      _isEnabled ? breadcrumb : null;
}
