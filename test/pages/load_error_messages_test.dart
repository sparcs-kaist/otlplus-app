import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/pages/main_page.dart';
import 'package:otlplus/pages/timetable_page.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/repositories/course_repository.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/repositories/lecture_repository.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/repositories/timetable_repository.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('timetable load error uses localized message and retry label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ChangeNotifierProvider<TimetableModel>.value(
          value: _FailedTimetableModel(),
          child: TimetablePage(),
        ),
      ),
    );

    expect(find.text('error.load_timetable'.tr()), findsOneWidget);
    expect(find.text('common.retry'.tr()), findsOneWidget);
  });

  testWidgets('user info load error uses localized message and retry label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ChangeNotifierProvider<InfoModel>.value(
          value: _FailedInfoModel(),
          child: MainPage(changeIndex: (_) {}),
        ),
      ),
    );

    expect(find.text('error.load_user_info'.tr()), findsOneWidget);
    expect(find.text('common.retry'.tr()), findsOneWidget);
  });

  testWidgets('semester load error uses localized message and retry label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ChangeNotifierProvider<InfoModel>.value(
          value: _EmptySemestersInfoModel(),
          child: MainPage(changeIndex: (_) {}),
        ),
      ),
    );

    expect(find.text('error.load_semesters'.tr()), findsOneWidget);
    expect(find.text('common.retry'.tr()), findsOneWidget);
  });

  testWidgets(
    'course detail load error uses localized message and retry label',
    (tester) async {
      await tester.pumpWidget(
        _app(
          ChangeNotifierProvider<CourseDetailModel>.value(
            value: _FailedCourseDetailModel(),
            child: CourseDetailPage(),
          ),
        ),
      );

      expect(find.text('error.load_course_details'.tr()), findsOneWidget);
      expect(find.text('common.retry'.tr()), findsOneWidget);
    },
  );

  testWidgets(
    'lecture detail load error uses localized message and retry label',
    (tester) async {
      await tester.pumpWidget(
        _app(
          ChangeNotifierProvider<LectureDetailModel>.value(
            value: _FailedLectureDetailModel(),
            child: LectureDetailPage(),
          ),
        ),
      );

      expect(find.text('error.load_lecture_details'.tr()), findsOneWidget);
      expect(find.text('common.retry'.tr()), findsOneWidget);
    },
  );
}

Widget _app(Widget home) {
  return MaterialApp(home: home);
}

class _FailedTimetableModel extends TimetableModel {
  _FailedTimetableModel()
    : super(repository: TimetableRepository(Dio()), forTest: true);

  @override
  bool get isLoaded => false;

  @override
  bool get loadFailed => true;
}

class _FailedInfoModel extends InfoModel {
  _FailedInfoModel()
    : super(infoRepository: InfoRepository(Dio()), forTest: true);

  @override
  bool get hasData => false;

  @override
  bool get hasError => true;
}

class _EmptySemestersInfoModel extends InfoModel {
  _EmptySemestersInfoModel()
    : super(infoRepository: InfoRepository(Dio()), forTest: true);

  @override
  bool get hasData => true;

  @override
  bool get hasError => false;

  @override
  List<Semester> get semesters => const <Semester>[];
}

class _FailedCourseDetailModel extends CourseDetailModel {
  _FailedCourseDetailModel()
    : super(
        CourseRepository(Dio()),
        LectureRepository(Dio()),
        ReviewRepository(Dio()),
      );

  @override
  bool get hasData => false;

  @override
  bool get loadFailed => true;
}

class _FailedLectureDetailModel extends LectureDetailModel {
  _FailedLectureDetailModel()
    : super(CourseRepository(Dio()), LectureRepository(Dio()));

  @override
  bool get hasData => false;

  @override
  bool get loadFailed => true;
}
