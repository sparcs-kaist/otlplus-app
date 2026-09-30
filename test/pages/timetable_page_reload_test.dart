import "dart:async";

import "package:dio/dio.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/models/semester.dart";
import "package:otlplus/constants/enums.dart";
import "package:otlplus/models/timetable.dart";
import "package:otlplus/models/user.dart";
import "package:otlplus/pages/timetable_page.dart";
import "package:otlplus/widgets/semester_picker.dart";
import "package:otlplus/widgets/timetable_tabs.dart";
import "package:otlplus/providers/lecture_search_model.dart";
import "package:otlplus/providers/timetable_model.dart";
import "package:otlplus/repositories/department_repository.dart";
import "package:otlplus/repositories/lecture_repository.dart";
import "package:otlplus/repositories/timetable_repository.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Semester browsing preserves the rendered page while new data is fetched.
class _ReloadFakeTimetableRepository extends TimetableRepository {
  _ReloadFakeTimetableRepository() : super(Dio());

  Completer<Timetable>? myTimetableCompleter;

  @override
  Future<Timetable> fetchMyTimetable(int year, int semester) {
    return myTimetableCompleter?.future ??
        Future<Timetable>.value(Timetable(id: -1, lectures: const []));
  }

  @override
  Future<TimetableCollection> fetchBySemester(int year, int semester) async {
    return TimetableCollection(
      summaries: [
        TimetableListItem(
          id: 7,
          name: "시간표 7",
          year: year,
          semester: Season.fall.code,
          timeTableOrder: 0,
        ),
      ],
      timetables: [Timetable(id: 7, lectures: const [])],
    );
  }
}

Semester _semester(int year, int season) {
  return Semester(
    year: year,
    semester: season,
    beginning: DateTime(year, 2, 1),
    end: DateTime(year, 6, 30),
  );
}

User _user() {
  return User(
    id: 1,
    email: "",
    studentId: "",
    firstName: "",
    lastName: "",
    majors: const [],
    departments: const [],
    myTimetableLectures: const [],
    reviewWritableLectures: const [],
    reviews: const [],
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    "semester loading preserves the layout, tabs and scroll position",
    (tester) async {
      final repository = _ReloadFakeTimetableRepository();
      final model = TimetableModel(repository: repository, forTest: true);
      await tester.runAsync(
        () => model.loadSemesters(
          user: _user(),
          semesters: [_semester(2025, 3), _semester(2026, 1)],
        ),
      );
      expect(model.isLoaded, isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TimetableModel>.value(value: model),
            ChangeNotifierProvider<LectureSearchModel>.value(
              value: LectureSearchModel(
                LectureRepository(Dio()),
                DepartmentRepository(Dio()),
              ),
            ),
          ],
          child: EasyLocalization(
            supportedLocales: const [Locale("ko")],
            path: "assets/translations",
            child: MaterialApp(home: Scaffold(body: TimetablePage())),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);

      final pickerState = tester.state(find.byType(SemesterPicker));
      final tabsState = tester.state(find.byType(TimetableTabs));
      final previousTimetable = model.currentTimetable;
      final scrollableFinder = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      );
      final scrollable = tester.state<ScrollableState>(scrollableFinder);
      scrollable.position.jumpTo(100);
      await tester.pump();

      // Hold the network response across several frames.
      repository.myTimetableCompleter = Completer<Timetable>();
      expect(model.goPreviousSemester(), isTrue);
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason:
            "selector re-evaluation during the reload window must not "
            "index into the empty timetable list",
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byKey(const Key('timetable_semester_loading')),
        findsOneWidget,
      );
      expect(tester.state(find.byType(SemesterPicker)), same(pickerState));
      expect(tester.state(find.byType(TimetableTabs)), same(tabsState));
      expect(tester.state<ScrollableState>(scrollableFinder), same(scrollable));
      expect(scrollable.position.pixels, 100);
      expect(model.currentTimetable, same(previousTimetable));
      expect(model.isLoaded, isFalse);
      expect(model.isLoading, isTrue);
      expect(await model.createTimetable(), isFalse);
      expect(await model.deleteTimetable(), isFalse);

      await tester.runAsync(() async {
        repository.myTimetableCompleter!.complete(
          Timetable(id: -1, lectures: const []),
        );
        await Future<void>.delayed(Duration.zero);
      });
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(model.isLoaded, isTrue);
      expect(find.byKey(const Key('timetable_semester_loading')), findsNothing);
      expect(tester.state(find.byType(SemesterPicker)), same(pickerState));
      expect(tester.state(find.byType(TimetableTabs)), same(tabsState));
      expect(scrollable.position.pixels, 100);

      // A failed switch keeps the semester controls available for recovery.
      repository.myTimetableCompleter = Completer<Timetable>();
      model.goNextSemester();
      await tester.pump();
      repository.myTimetableCompleter!.completeError(
        DioException(requestOptions: RequestOptions(path: '/timetable')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(model.loadFailed, isTrue);
      expect(find.byKey(const Key('timetable_error')), findsOneWidget);
      expect(tester.state(find.byType(SemesterPicker)), same(pickerState));
      repository.myTimetableCompleter = null;
      await model.retryLoad();
      await tester.pump(const Duration(milliseconds: 200));
      expect(model.isLoaded, isTrue);
      expect(find.byKey(const Key('timetable_error')), findsNothing);
      expect(tester.state(find.byType(SemesterPicker)), same(pickerState));
      expect(tester.takeException(), isNull);
    },
  );
}
