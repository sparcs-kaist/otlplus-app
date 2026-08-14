import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/services/sentry_consent_gate.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:provider/provider.dart';

class TelemetrySynchronizer extends StatefulWidget {
  const TelemetrySynchronizer({
    required this.child,
    required this.sentryConsentGate,
    required this.telemetry,
    super.key,
  });

  final Widget child;
  final SentryConsentGate sentryConsentGate;
  final TelemetryCoordinator telemetry;

  @override
  State<TelemetrySynchronizer> createState() => _TelemetrySynchronizerState();
}

class _TelemetrySynchronizerState extends State<TelemetrySynchronizer> {
  TelemetryState? _scheduledState;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    final info = context.watch<InfoModel>();
    final state = TelemetryState(
      isReady: settings.isLoaded,
      crashlyticsEnabled: settings.getSendCrashlytics(),
      crashlyticsAnonymous: settings.getSendCrashlyticsAnonymously(),
      analyticsEnabled: settings.getSendAnalytics(),
      userIdentifier: info.hasData ? info.user.id.toString() : null,
    );

    if (state.isReady) {
      unawaited(
        widget.sentryConsentGate.setEnabled(state.crashlyticsEnabled),
      );
    }

    if (state.isReady && state != _scheduledState) {
      _scheduledState = state;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(widget.telemetry.synchronize(state));
        }
      });
    }

    return widget.child;
  }
}
