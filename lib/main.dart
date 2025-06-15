import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/pages/liked_review_page.dart';
import 'package:otlplus/pages/my_review_page.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/liked_review_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/services/storage_service.dart';
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

import 'firebase_options.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );

    final token = await FirebaseMessaging.instance.getToken();

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    await ChannelTalk.boot(
        pluginKey: '0abc4b50-9e66-4b45-b910-eb654a481f08',
        memberHash: token,
        language: Language.korean,
        appearance: Appearance.light,
        channelButtonOption: ChannelButtonOption(
            position: ChannelButtonPosition.right, xMargin: 16, yMargin: 130));

    await ChannelTalk.initPushToken(deviceToken: token ?? "");

    await ChannelTalk.showChannelButton();

    runApp(
      EasyLocalization(
          supportedLocales: [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: Locale('en'),
          child: MultiProvider(
            providers: [
              Provider(create: (_) => StorageService()),
              ChangeNotifierProvider(
                  create: (context) =>
                      AuthModel(context.read<StorageService>())),
              ChangeNotifierProxyProvider<AuthModel, InfoModel>(
                create: (context) => InfoModel(),
                update: (context, authModel, infoModel) {
                  if (authModel.isLogined && infoModel != null) {
                    infoModel.getInfo().catchError((error) async {
                      print("Error getting user info: $error. Logging out.");
                      // Add a small delay to prevent rapid state changes
                      await Future.delayed(Duration(milliseconds: 100));
                      if (authModel.isLogined) {
                        await authModel.logout();
                      }
                    });
                  } else if (!authModel.isLogined && infoModel != null) {
                    infoModel.clearData();
                  }
                  return infoModel ?? InfoModel();
                },
              ),
              ChangeNotifierProxyProvider<InfoModel, TimetableModel>(
                create: (context) => TimetableModel(),
                update: (context, infoModel, timetableModel) {
                  if (infoModel.hasData && timetableModel != null) {
                    timetableModel.loadSemesters(
                        user: infoModel.user, semesters: infoModel.semesters);
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
              ChangeNotifierProvider(create: (_) => SettingsModel()),
            ],
            child: OTLApp(),
          )),
    );
  },
      (error, stack) =>
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class OTLApp extends StatefulWidget {
  @override
  _OTLAppState createState() => _OTLAppState();
}

class _OTLAppState extends State<OTLApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final _storageService = StorageService();
  final _dio = DioProvider().dio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final authModel = Provider.of<AuthModel>(context, listen: false);

    if (await _storageService.hasTokens()) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        authModel.setLoggedIn(true);
      } else {
        await _storageService.deleteTokens();
        authModel.setLoggedIn(false);
      }
    } else {
      authModel.setLoggedIn(false);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _refreshToken() async {
    final currentAccessToken = await _storageService.getAccessToken();
    final currentRefreshToken = await _storageService.getRefreshToken();

    if (currentAccessToken == null || currentRefreshToken == null) {
      return false;
    }

    try {
      final response = await _dio.post(
        SESSION_REFRESH_URL,
        data: {
          'accessToken': currentAccessToken,
          'refreshToken': currentRefreshToken,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];

        if (newAccessToken != null && newRefreshToken != null) {
          await _storageService.saveTokens(
              accessToken: newAccessToken, refreshToken: newRefreshToken);
          return true;
        }
      }
    } on DioException catch (e) {
      print("Error refreshing token: ${e.response?.statusCode} - ${e.message}");
    } catch (e) {
      print("Unexpected error refreshing token: $e");
    }
    return false;
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
      String accessToken, String refreshToken) async {
    await _storageService.saveTokens(
        accessToken: accessToken, refreshToken: refreshToken);
    Provider.of<AuthModel>(context, listen: false).setLoggedIn(true);
    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (DioProvider.navigatorContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          DioProvider.setNavigatorContext(context);
        }
      });
    }

    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final authModel = context.watch<AuthModel>();

    return MaterialApp(
      builder: (context, child) {
        try {
          final sendCrashlytics =
              context.watch<SettingsModel>().getSendCrashlytics();
          final sendCrashlyticsAnonymously =
              context.watch<SettingsModel>().getSendCrashlyticsAnonymously();
          final hasData = context.watch<InfoModel>().hasData;

          FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(sendCrashlytics);
          if (!sendCrashlyticsAnonymously && hasData) {
            FirebaseCrashlytics.instance
                .setUserIdentifier(context.watch<InfoModel>().user.id.toString());
          } else if (!sendCrashlytics) {
            FirebaseCrashlytics.instance.setUserIdentifier('');
          }
        } catch (e) {
          print("Error accessing settings/info for Crashlytics: $e");
        }

        return ScrollConfiguration(
          behavior: NoEndOfScrollBehavior(),
          child: child ?? Container(),
        );
      },
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
        hintStyle: TextStyle(
          color: OTLColor.pinksMain,
          fontSize: 14.0,
        ),
      ),
    );

    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(margin: const EdgeInsets.only()),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: OTLColor.grayE,
        pressElevation: 0.0,
        secondarySelectedColor: OTLColor.grayD,
        labelStyle: const TextStyle(
          color: OTLColor.gray3,
          fontSize: 12.0,
        ),
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
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
