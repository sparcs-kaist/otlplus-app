import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:otlplus/services/posthog_service.dart';

abstract interface class CrashReportingClient {
  Future<void> deleteUnsentReports();
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
    required String reason,
  });
  Future<void> recordFlutterFatalError(FlutterErrorDetails details);
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> setUserIdentifier(String identifier);
}

class FirebaseCrashReportingClient implements CrashReportingClient {
  const FirebaseCrashReportingClient();

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  @override
  Future<void> deleteUnsentReports() => _crashlytics.deleteUnsentReports();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
    required String reason,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      reason: reason,
    );
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) {
    return _crashlytics.recordFlutterFatalError(details);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> setUserIdentifier(String identifier) {
    return _crashlytics.setUserIdentifier(identifier);
  }
}

class TelemetryState {
  const TelemetryState({
    required this.isReady,
    required this.crashlyticsEnabled,
    required this.crashlyticsAnonymous,
    required this.analyticsEnabled,
    required this.userIdentifier,
  });

  final bool isReady;
  final bool crashlyticsEnabled;
  final bool crashlyticsAnonymous;
  final bool analyticsEnabled;
  final String? userIdentifier;

  @override
  bool operator ==(Object other) {
    return other is TelemetryState &&
        isReady == other.isReady &&
        crashlyticsEnabled == other.crashlyticsEnabled &&
        crashlyticsAnonymous == other.crashlyticsAnonymous &&
        analyticsEnabled == other.analyticsEnabled &&
        userIdentifier == other.userIdentifier;
  }

  @override
  int get hashCode => Object.hash(
    isReady,
    crashlyticsEnabled,
    crashlyticsAnonymous,
    analyticsEnabled,
    userIdentifier,
  );
}

/// Serializes SDK state changes so consent and identity updates cannot race.
class TelemetryCoordinator {
  TelemetryCoordinator({
    required AnalyticsClient analytics,
    required CrashReportingClient crashReporting,
  }) : _analytics = analytics,
       _crashReporting = crashReporting;

  final AnalyticsClient _analytics;
  final CrashReportingClient _crashReporting;
  Future<void> _operations = Future<void>.value();
  TelemetryState? _requestedState;

  Future<void> initialize() => _analytics.initialize();

  Future<void> synchronize(TelemetryState state) {
    if (!state.isReady || state == _requestedState) return _operations;

    _requestedState = state;
    _operations = _operations
        .catchError((_) {})
        .then((_) => _applyState(state));
    return _operations;
  }

  Future<void> recordFatal(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) {
    return _crashReporting.recordError(
      error,
      stackTrace,
      fatal: true,
      reason: reason,
    );
  }

  Future<void> recordFlutterFatalError(FlutterErrorDetails details) {
    return _crashReporting.recordFlutterFatalError(details);
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) {
    return _crashReporting.recordError(
      StateError('$operation failed (${error.runtimeType})'),
      stackTrace,
      fatal: false,
      reason: operation,
    );
  }

  Future<void> _applyState(TelemetryState state) async {
    final identifier = state.crashlyticsEnabled &&
            !state.crashlyticsAnonymous &&
            state.userIdentifier != null
        ? state.userIdentifier!
        : '';

    if (state.crashlyticsEnabled) {
      await _crashReporting.setUserIdentifier(identifier);
      await _crashReporting.setCollectionEnabled(true);
    } else {
      await _crashReporting.setCollectionEnabled(false);
      await _crashReporting.setUserIdentifier('');
    }

    if (state.analyticsEnabled) {
      await _analytics.enable();
    } else {
      await _analytics.disable();
      await _analytics.reset();
    }

    if (!state.crashlyticsEnabled) {
      await _crashReporting.deleteUnsentReports();
    }
  }
}
