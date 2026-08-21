import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/pages/course_search_page.dart';
import 'package:otlplus/pages/dictionary_page.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/pages/lecture_search_page.dart';
import 'package:otlplus/pages/main_page.dart';
import 'package:otlplus/pages/my_review_page.dart';
import 'package:otlplus/pages/people_page.dart';
import 'package:otlplus/pages/privacy_page.dart';
import 'package:otlplus/pages/settings_page.dart';
import 'package:otlplus/pages/timetable_page.dart';
import 'package:otlplus/pages/user_page.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/extensions.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets("pump CourseDetailPage", (WidgetTester tester) async {
    tester.pumpWidget(
      CourseDetailPage().scaffoldAndNotifier(CourseDetailModel()),
    );
  });

  testWidgets("pump CourseSearchPage", (WidgetTester tester) async {
    tester.pumpWidget(
      CourseSearchPage().scaffoldAndNotifier(CourseSearchModel()),
    );
  });

  testWidgets("pump DictionaryPage", (WidgetTester tester) async {
    final searchModel = CourseSearchModel()
      ..setSearchText("robot")
      ..setCourseFilterSelected("types", "BR", true);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale("ko")],
        path: "assets/translations",
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<CourseSearchModel>.value(value: searchModel),
            ChangeNotifierProvider<CourseDetailModel>(
              create: (_) => CourseDetailModel(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: DictionaryPage())),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('"robot"'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("pump LectureDetailPage", (WidgetTester tester) async {
    tester.pumpWidget(
      LectureDetailPage().scaffoldAndNotifier(LectureDetailModel()),
    );
  });

  testWidgets("pump LectureSearchPage", (WidgetTester tester) async {
    tester.pumpWidget(
      LectureSearchPage().scaffoldAndNotifier(LectureSearchModel()),
    );
  });

  testWidgets("pump LikedReviewPage", (WidgetTester tester) async {
    // tester.pumpWidget(LikedReviewPage().scaffoldAndNotifiers([InfoModel(forTest: true), LikedReviewModel()]));
  });

  testWidgets("pump LoginPage", (WidgetTester tester) async {
    // tester.pumpWidget(LoginPage().material);
  });

  testWidgets("pump MainPage", (WidgetTester tester) async {
    tester.pumpWidget(
      MainPage(
        changeIndex: (int index) {},
      ).materialAndNotifier(InfoModel(forTest: true)),
    );
  });

  testWidgets("pump MyReviewPage", (WidgetTester tester) async {
    tester.pumpWidget(
      MyReviewPage().materialAndNotifier(InfoModel(forTest: true)),
    );
  });

  testWidgets("pump PeoplePage", (WidgetTester tester) async {
    tester.pumpWidget(PeoplePage().material);
  });

  testWidgets("pump PrivacyPage", (WidgetTester tester) async {
    tester.pumpWidget(PrivacyPage().material);
  });

  testWidgets("pump ReviewPage", (WidgetTester tester) async {
    // tester.pumpWidget(ReviewPage().scaffoldAndNotifiers([InfoModel(forTest: true), ReviewModel()]));
  });

  testWidgets("pump SettingsPage", (WidgetTester tester) async {
    tester.pumpWidget(
      SettingsPage().materialAndNotifier(SettingsModel(forTest: true)),
    );
  });

  testWidgets("pump TimetablePage", (WidgetTester tester) async {
    tester.pumpWidget(TimetablePage().materialAndNotifier(TimetableModel()));
  });

  testWidgets("pump UserPage", (WidgetTester tester) async {
    tester.pumpWidget(UserPage().materialAndNotifier(InfoModel(forTest: true)));
  });
}
