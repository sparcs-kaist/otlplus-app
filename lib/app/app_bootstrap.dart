import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/app/providers_setup.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/firebase_options.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/services/channel_talk_readiness.dart';
import 'package:otlplus/services/optional_bootstrap.dart';
import 'package:otlplus/services/channel_talk_analytics_service.dart';
import 'package:otlplus/services/sentry_consent_gate.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final telemetryCoordinator = TelemetryCoordinator(
  analytics: ChannelTalkAnalyticsService(),
  crashReporting: const FirebaseCrashReportingClient(),
);
final sentryConsentGate = SentryConsentGate();
const _isSmokeTest = bool.fromEnvironment('APP_SMOKE_TEST');

Future<void> initializeAppSession({
  required AuthModel authModel,
  required StorageService storageService,
  required bool Function() isMounted,
  required VoidCallback onLoaded,
}) async {
  try {
    await () async {
      if (await storageService.hasTokens()) {
        final result = await DioProvider().refreshSession();
        if (result == SessionRefreshResult.rejected) {
          authModel.setLoggedIn(await storageService.hasTokens());
        } else {
          // Refresh succeeded, or the network was unavailable. Keep the
          // stored session; the 401 interceptor decides once online.
          authModel.setLoggedIn(true);
        }
      } else {
        authModel.setLoggedIn(false);
      }
    }().timeout(const Duration(seconds: 15));
  } catch (error, stackTrace) {
    unawaited(
      telemetryCoordinator.recordNonFatal(
        error,
        stackTrace,
        operation: 'app_initialization',
      ),
    );
  } finally {
    if (isMounted()) {
      onLoaded();
    }
  }
}

void bootstrapApp(Widget Function() appBuilder) {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      var crashReportingEnabled = false;
      if (!_isSmokeTest) {
        crashReportingEnabled = await SettingsModel.loadCrashReportingEnabled();
        await sentryConsentGate.setEnabled(crashReportingEnabled);
        await Sentry.init(sentryConsentGate.configure);
      }
      await EasyLocalization.ensureInitialized();

      if (!_isSmokeTest) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await telemetryCoordinator.initialize(
        crashReportingEnabled: crashReportingEnabled,
      );
      DioProvider.configureTelemetry(telemetryCoordinator);

      FlutterError.onError = (details) {
        unawaited(telemetryCoordinator.recordFlutterFatalError(details));
        if (sentryConsentGate.isEnabled) {
          Sentry.captureException(details.exception, stackTrace: details.stack);
        }
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(
          telemetryCoordinator.recordFatal(
            error,
            stackTrace,
            reason: 'platform_dispatcher_error',
          ),
        );
        if (sentryConsentGate.isEnabled) {
          Sentry.captureException(error, stackTrace: stackTrace);
        }
        return true;
      };

      runApp(
        EasyLocalization(
          supportedLocales: [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: Locale('en'),
          child: Builder(
            builder: (context) {
              final locale = context.locale.languageCode;
              DioProvider.configureLocaleSupplier(() => locale);
              return buildAppProviders(
                child: appBuilder(),
                telemetryCoordinator: telemetryCoordinator,
                sentryConsentGate: sentryConsentGate,
              );
            },
          ),
        ),
      );

      if (!_isSmokeTest) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(
            OptionalBootstrap(
              recordNonFatal: (error, stack) =>
                  telemetryCoordinator.recordNonFatal(
                    error,
                    stack,
                    operation: 'optional_bootstrap',
                  ),
            ).run(),
          ),
        );
      } else {
        sharedChannelTalkReadiness.markUnavailable();
      }
    },
    (error, stack) {
      unawaited(
        telemetryCoordinator.recordFatal(
          error,
          stack,
          reason: 'uncaught_zone_error',
        ),
      );
      if (sentryConsentGate.isEnabled) {
        Sentry.captureException(error, stackTrace: stack);
      }
    },
  );
}
