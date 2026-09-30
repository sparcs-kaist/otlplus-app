import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/home.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/latest_reviews_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/repositories/course_repository.dart';
import 'package:otlplus/repositories/department_repository.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/repositories/timetable_repository.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Android back goes home from every tab, then permits exit', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await _pumpHome(tester, navigator);
    expect(_bottomNav(tester).currentIndex, 0);
    expect(
      ModalRoute.of(tester.element(find.byType(OTLHome)))!.popDisposition,
      RoutePopDisposition.bubble,
    );

    for (final index in [1, 2, 3]) {
      _bottomNav(tester).onTap!(index);
      await tester.pump();
      expect(_bottomNav(tester).currentIndex, index);
      expect(await navigator.currentState!.maybePop(), isTrue);
      await tester.pump();
      expect(_bottomNav(tester).currentIndex, 0);
      expect(find.byType(OTLHome), findsOneWidget);
      // Returning false lets the Android embedding handle root app exit.
      expect(await navigator.currentState!.maybePop(), isFalse);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Android back dismisses details and dialogs before going home', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await _pumpHome(tester, navigator);
    _bottomNav(tester).onTap!(1);
    await tester.pump();
    final homeContext = tester.element(find.byType(OTLHome));
    OTLNavigator.push(homeContext, const Scaffold(body: Text('detail')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    OTLNavigator.pushDialog<void>(
      context: tester.element(find.text('detail')),
      builder: (_) => const AlertDialog(content: Text('dialog')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await navigator.currentState!.maybePop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('dialog'), findsNothing);
    expect(find.text('detail'), findsOneWidget);
    await navigator.currentState!.maybePop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('detail'), findsNothing);
    expect(_bottomNav(tester).currentIndex, 1);
    await navigator.currentState!.maybePop();
    await tester.pump();
    expect(_bottomNav(tester).currentIndex, 0);
    expect(OTLNavigator.canPop, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}

BottomNavigationBar _bottomNav(WidgetTester tester) =>
    tester.widget(find.byKey(const Key('home_bottom_nav')));

Future<void> _pumpHome(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigator,
) async {
  SharedPreferences.setMockInitialValues({'notification_consent_shown': true});
  final dio = Dio();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsModel(forTest: true)),
        ChangeNotifierProvider(
          create: (_) =>
              InfoModel(infoRepository: InfoRepository(dio), forTest: true),
        ),
        ChangeNotifierProvider(
          create: (_) => TimetableModel(repository: TimetableRepository(dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseSearchModel(
            CourseRepository(dio),
            DepartmentRepository(dio),
          ),
        ),
        ChangeNotifierProvider<HallOfFameModel>(
          create: (_) => _HallOfFameModel(dio),
        ),
        ChangeNotifierProvider(
          create: (_) => LatestReviewsModel(ReviewRepository(dio)),
        ),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('ko')],
        path: 'assets/translations',
        assetLoader: _TestAssetLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            navigatorKey: navigator,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: ThemeData(platform: TargetPlatform.android),
            home: const OTLHome(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump();
}

class _HallOfFameModel extends HallOfFameModel {
  _HallOfFameModel(Dio dio) : super(ReviewRepository(dio));

  @override
  Future<void> load() async {}
}

class _TestAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}
