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

  void configure(SentryFlutterOptions options) {
    options
      ..dsn =
          'https://dffaeddd63d8b6419fa3a5ca525bc047@sentry.sparcs.org/2'
      ..beforeSend = (event, hint) => filterEvent(event)
      ..beforeSendTransaction = (transaction, hint) =>
          filterTransaction(transaction)
      ..beforeBreadcrumb = (breadcrumb, hint) => filterBreadcrumb(breadcrumb)
      // Native automatic collection bypasses Dart beforeSend callbacks.
      ..enableNativeCrashHandling = false
      ..enableAutoSessionTracking = false
      ..anrEnabled = false
      ..enableAutoNativeBreadcrumbs = false
      ..enableWatchdogTerminationTracking = false
      ..enableAppHangTracking = false
      ..enableUserInteractionBreadcrumbs = false
      ..enableUserInteractionTracing = false
      ..enableAutoPerformanceTracing = false
      ..enableFramesTracking = false
      ..enableNativeTraceSync = false
      ..enableNdkScopeSync = false
      ..maxCacheItems = 0;
  }
}
