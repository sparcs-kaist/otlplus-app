import 'package:sentry_flutter/sentry_flutter.dart';

/// Keeps Sentry's Dart telemetry aligned with the crash reporting setting.
class SentryConsentGate {
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  Future<void> setEnabled(bool enabled) async {
    final wasEnabled = _isEnabled;
    _isEnabled = enabled;
    if (wasEnabled && !enabled) {
      await Sentry.configureScope((scope) => scope.clear());
    }
  }

  SentryEvent? filterEvent(SentryEvent event) => _isEnabled ? event : null;

  SentryTransaction? filterTransaction(SentryTransaction transaction) =>
      _isEnabled ? transaction : null;

  Breadcrumb? filterBreadcrumb(Breadcrumb? breadcrumb) =>
      _isEnabled ? breadcrumb : null;

  void configure(SentryOptions options) {
    options
      ..dsn =
          'https://dffaeddd63d8b6419fa3a5ca525bc047@sentry.sparcs.org/2'
      ..beforeSend = (event, hint) => filterEvent(event)
      ..beforeSendTransaction = (transaction, hint) =>
          filterTransaction(transaction)
      ..beforeBreadcrumb = (breadcrumb, hint) => filterBreadcrumb(breadcrumb)
      ..captureFailedRequests = false
      ..recordHttpBreadcrumbs = false
      ..sendClientReports = false
      ..enableMetrics = false
      ..enableLogs = false
      ..tracePropagationTargets.clear();
  }
}
