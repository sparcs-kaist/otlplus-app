import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/pages/liked_review_page.dart';
import 'package:otlplus/pages/my_review_page.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/liked_review_model.dart';
import 'package:otlplus/providers/settings_model.dart';
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
import 'package:sentry_flutter/sentry_flutter.dart';


Future<void> main() async {
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
        pluginKey: '0abc4b50-9e66-4b45-b910-eb654a481f08', // Required
        memberHash: token,
        language: Language.korean,
        appearance: Appearance.light,
        channelButtonOption: ChannelButtonOption(
            position: ChannelButtonPosition.right, xMargin: 16, yMargin: 130));

    await ChannelTalk.initPushToken(deviceToken: token ?? "");

    await ChannelTalk.showChannelButton();

    await SentryFlutter.init(
    (options) {
      options.dsn = 'https://dffaeddd63d8b6419fa3a5ca525bc047@sentry.sparcs.org/2';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: 
      EasyLocalization(
          supportedLocales: [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: Locale('en'),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => AuthModel()),
              ChangeNotifierProxyProvider<AuthModel, InfoModel>(
                create: (context) => InfoModel(),
                update: (context, authModel, infoModel) {
                  if (authModel.isLogined)
                    infoModel?.getInfo().catchError((error) async {
                      await authModel.logout();
                      throw error;
                    });
                  return (infoModel is InfoModel) ? infoModel : InfoModel();
                },
              ),
              ChangeNotifierProxyProvider<InfoModel, TimetableModel>(
                create: (context) => TimetableModel(),
                update: (context, infoModel, timetableModel) {
                  if (infoModel.hasData) {
                    timetableModel?.loadSemesters(
                        user: infoModel.user, semesters: infoModel.semesters);
                  }
                  return (timetableModel is TimetableModel)
                      ? timetableModel
                      : TimetableModel();
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
            child: OTLFirebaseApp(),
          )),
      )
      ),
    );
  },
  (error, stack) =>
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class OTLFirebaseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      }
    } on Error {}

    return MaterialApp(
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: NoEndOfScrollBehavior(),
          child: child ?? Container(),
        );
      },
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: "OTL",
      home: context.select<InfoModel, bool>((model) => model.hasData)
          ? OTLHome()
          : LoginPage(),
      routes: {
        LikedReviewPage.route: (_) => LikedReviewPage(),
        MyReviewPage.route: (_) => MyReviewPage(),
        LectureDetailPage.route: (_) => LectureDetailPage(),
        CourseDetailPage.route: (_) => CourseDetailPage(),
      },
      theme: _buildTheme(),
      //builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0), child: child!),
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
