import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/models/professor.dart';
import 'package:otlplus/pages/dictionary_page.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/repositories/course_repository.dart';
import 'package:otlplus/repositories/department_repository.dart';
import 'package:otlplus/repositories/lecture_repository.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/course_block.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('builder renders from a single snapshot of the course list', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final courses = List<Course>.generate(8, _course);

    await _pumpDictionaryPage(
      tester,
      searchModel: _FlakyCourseSearchModel(courses),
      detailModel: _CourseDetailModel(),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CourseBlock), findsNWidgets(8));
  });

  testWidgets('course blocks use course ids as stable keys', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final courses = List<Course>.generate(3, _course);

    await _pumpDictionaryPage(
      tester,
      searchModel: _CourseSearchModel(courses),
      detailModel: _CourseDetailModel(),
    );

    final firstCourseBlock = tester.widget<CourseBlock>(
      find.byType(CourseBlock).first,
    );
    expect(firstCourseBlock.key, ValueKey(courses.first.id));
  });

  testWidgets(
    'tap callback uses snapshot when live list is cleared before invocation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final courses = List<Course>.generate(8, _course);
      final searchModel = _CourseSearchModel(courses);
      final detailModel = _CourseDetailModel();
      final navigatorKey = GlobalKey<NavigatorState>();

      await _pumpDictionaryPage(
        tester,
        searchModel: searchModel,
        detailModel: detailModel,
        navigatorKey: navigatorKey,
      );
      final retainedBlock = tester.widget<CourseBlock>(
        find.byType(CourseBlock).at(7),
      );

      searchModel.setCourses(null);

      expect(retainedBlock.onTap!, returnsNormally);
      expect(detailModel.loadedCourseIds, <int>[courses[7].id]);
      expect(tester.takeException(), isNull);

      OTLNavigator.pop(navigatorKey.currentContext!);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'rebuild with shorter refreshed list shows new count without range error',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final searchModel = _CourseSearchModel(List<Course>.generate(8, _course));

      await _pumpDictionaryPage(
        tester,
        searchModel: searchModel,
        detailModel: _CourseDetailModel(),
      );
      expect(find.byType(CourseBlock), findsNWidgets(8));

      searchModel.setCourses(List<Course>.generate(3, _course));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CourseBlock), findsNWidgets(3));
    },
  );
}

Future<void> _pumpDictionaryPage(
  WidgetTester tester, {
  required CourseSearchModel searchModel,
  required CourseDetailModel detailModel,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CourseSearchModel>.value(value: searchModel),
        ChangeNotifierProvider<CourseDetailModel>.value(value: detailModel),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('ko')],
        path: 'assets/translations',
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: DictionaryPage()),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _CourseSearchModel extends CourseSearchModel {
  _CourseSearchModel(this._courseValues)
    : super(CourseRepository(Dio()), DepartmentRepository(Dio()));

  List<Course>? _courseValues;

  @override
  List<Course>? get courses => _courseValues;

  void setCourses(List<Course>? courses) {
    _courseValues = courses;
    notifyListeners();
  }
}

class _FlakyCourseSearchModel extends CourseSearchModel {
  _FlakyCourseSearchModel(this._initialCourses)
    : super(CourseRepository(Dio()), DepartmentRepository(Dio()));

  final List<Course> _initialCourses;
  int _readCount = 0;

  @override
  List<Course>? get courses => _readCount++ == 0 ? _initialCourses : null;
}

class _CourseDetailModel extends CourseDetailModel {
  _CourseDetailModel()
    : super(
        CourseRepository(Dio()),
        LectureRepository(Dio()),
        ReviewRepository(Dio()),
      );

  final List<int> loadedCourseIds = <int>[];

  @override
  Future<void> loadCourse(int courseId) async {
    loadedCourseIds.add(courseId);
  }
}

Course _course(int index) {
  final id = index + 1;
  return Course(
    id: id,
    oldCode: 'TEST.$id',
    type: 'Type',
    typeEn: 'Type',
    title: 'Course $id',
    titleEn: 'Course $id',
    summary: 'Summary $id',
    reviewTotalWeight: 0,
    professors: <Professor>[],
    grade: 0,
    load: 0,
    speech: 0,
    userspecificIsRead: false,
  );
}
