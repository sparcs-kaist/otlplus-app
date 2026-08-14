import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/pages/liked_review_page.dart';
import 'package:otlplus/pages/my_review_page.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/liked_review_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/sentry_consent_gate.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:otlplus/widgets/telemetry_synchronizer.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/home.dart';
import 'package:otlplus/pages/login_page.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/providers/latest_reviews_model.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/utils/create_material_color.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:channel_talk_flutter/channel_talk_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'firebase_options.dart';

final telemetryCoordinator = TelemetryCoordinator(
  analytics: PostHogService(),
  crashReporting: const FirebaseCrashReportingClient(),
);
final sentryConsentGate = SentryConsentGate();
const _isSmokeTest = bool.fromEnvironment('APP_SMOKE_TEST');

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      if (!_isSmokeTest) {
        await Sentry.init(sentryConsentGate.configure);
      }
      await EasyLocalization.ensureInitialized();

      if (!_isSmokeTest) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await telemetryCoordinator.initialize();
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

      if (!_isSmokeTest) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: true,
          sound: true,
        );

        final token = await FirebaseMessaging.instance.getToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );

        await ChannelTalk.boot(
          pluginKey: '0abc4b50-9e66-4b45-b910-eb654a481f08',
          memberHash: token,
          language: Language.korean,
          appearance: Appearance.light,
          channelButtonOption: ChannelButtonOption(
            position: ChannelButtonPosition.right,
            xMargin: 16,
            yMargin: 130,
          ),
        ).timeout(const Duration(seconds: 10));

        await ChannelTalk.initPushToken(deviceToken: token ?? "");
        await ChannelTalk.showChannelButton();
      }

      runApp(
        EasyLocalization(
          supportedLocales: [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: Locale('en'),
          child: MultiProvider(
            providers: [
              Provider(create: (_) => StorageService()),
              ChangeNotifierProvider(
                create: (context) => AuthModel(
                  context.read<StorageService>(),
                  telemetry: telemetryCoordinator,
                ),
              ),
              ChangeNotifierProxyProvider<AuthModel, InfoModel>(
                create: (context) => InfoModel(telemetry: telemetryCoordinator),
                update: (context, authModel, infoModel) {
                  if (authModel.isLogined && infoModel != null) {
                    // Failures set InfoModel.hasError for retry UI; session
                    // expiry is handled by the Dio interceptor.
                    unawaited(infoModel.getInfo());
                  } else if (!authModel.isLogined && infoModel != null) {
                    infoModel.clearData();
                  }
                  return infoModel ??
                      InfoModel(telemetry: telemetryCoordinator);
                },
              ),
              ChangeNotifierProxyProvider<InfoModel, TimetableModel>(
                create: (context) => TimetableModel(),
                update: (context, infoModel, timetableModel) {
                  if (infoModel.hasData && timetableModel != null) {
                    timetableModel.loadSemesters(
                      user: infoModel.user,
                      semesters: infoModel.semesters,
                    );
                  } else if (!infoModel.hasData && timetableModel != null) {}
                  return timetableModel ?? TimetableModel();
                },
              ),
              ChangeNotifierProvider(create: (_) => LectureSearchModel()),
              ChangeNotifierProvider(create: (_) => CourseSearchModel()),
              ChangeNotifierProvider(create: (_) => LatestReviewsModel()),
              ChangeNotifierProvider(create: (_) => LikedReviewModel()),
              ChangeNotifierProvider(create: (_) => HallOfFameModel()),
              ChangeNotifierProvider(create: (_) => CourseDetailModel()),
              ChangeNotifierProvider(create: (_) => LectureDetailModel()),
              ChangeNotifierProvider(
                create: (_) => SettingsModel(
                  onCrashReportingChanged: (enabled) {
                    unawaited(sentryConsentGate.setEnabled(enabled));
                  },
                ),
              ),
            ],
            child: TelemetrySynchronizer(
              telemetry: telemetryCoordinator,
              child: OTLApp(),
            ),
          ),
        ),
      );
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

class OTLApp extends StatefulWidget {
  @override
  _OTLAppState createState() => _OTLAppState();
}

class _OTLAppState extends State<OTLApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final _storageService = StorageService();
  bool _isLoading = true;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _initDeepLinks();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (info.immediateUpdateAllowed && info.updatePriority >= 4) {
            final result = await InAppUpdate.performImmediateUpdate();
            if (result == AppUpdateResult.userDeniedUpdate) {
              exit(0);
            }
          } else if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate().then((_) {
              _showUpdateSnackbar();
            });
          }
        } else if (info.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress) {
          await InAppUpdate.performImmediateUpdate();
        }
      } catch (e) {
        debugPrint("In-app update error: $e");
      }
    }
  }

  void _showUpdateSnackbar() {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text("popup.inapp_flexible_download_complete".tr()),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: "popup.inapp_flexible_restart".tr(),
          onPressed: () async {
            await InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final authModel = Provider.of<AuthModel>(context, listen: false);

    try {
      await () async {
        if (await _storageService.hasTokens()) {
          final result = await DioProvider().refreshSession();
          if (result == SessionRefreshResult.rejected) {
            await _storageService.deleteTokens();
            authModel.setLoggedIn(false);
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.host == 'login' && uri.path == '/') {
        final accessToken = uri.queryParameters['accessToken'];
        final refreshToken = uri.queryParameters['refreshToken'];

        if (accessToken != null && refreshToken != null) {
          _handleLoginTokens(accessToken, refreshToken);
        }
      }
    });
  }

  Future<void> _handleLoginTokens(
    String accessToken,
    String refreshToken,
  ) async {
    await _storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    Provider.of<AuthModel>(context, listen: false).setLoggedIn(true);
    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final authModel = context.watch<AuthModel>();
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      builder: (context, child) => ScrollConfiguration(
        behavior: NoEndOfScrollBehavior(),
        child: child ?? Container(),
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: "OTL",
      home: authModel.isLogined ? OTLHome() : LoginPage(),
      routes: {
        LikedReviewPage.route: (_) => LikedReviewPage(),
        MyReviewPage.route: (_) => MyReviewPage(),
        LectureDetailPage.route: (_) => LectureDetailPage(),
        CourseDetailPage.route: (_) => CourseDetailPage(),
        LoginPage.route: (_) => LoginPage(),
      },
      theme: _buildTheme(),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: false,
      fontFamily: 'NotoSansKR',
      primarySwatch: createMaterialColor(OTLColor.pinksMain),
      canvasColor: OTLColor.grayF,
      iconTheme: const IconThemeData(color: OTLColor.gray3),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(),
        isDense: true,
        hintStyle: TextStyle(color: OTLColor.pinksMain, fontSize: 14.0),
      ),
    );

    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(margin: const EdgeInsets.only()),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: OTLColor.grayE,
        pressElevation: 0.0,
        secondarySelectedColor: OTLColor.grayD,
        labelStyle: const TextStyle(color: OTLColor.gray3, fontSize: 12.0),
        secondaryLabelStyle: const TextStyle(
          color: OTLColor.gray3,
          fontSize: 12.0,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: OTLColor.gray3,
        displayColor: OTLColor.gray3,
      ),
    );
  }
}

class NoEndOfScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
