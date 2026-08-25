import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/extensions/semester.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/nested_lecture.dart';
import 'package:otlplus/models/professor.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/pages/my_review_page.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/repositories/course_repository.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/repositories/lecture_repository.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/widgets/hall_of_fame_control.dart';
import 'package:otlplus/widgets/review_block.dart';
import 'package:provider/provider.dart';

import '../utils/samples.dart';

void main() {
  testWidgets('HallOfFameControl renders summer for semester code 2', (
    tester,
  ) async {
    await tester.pumpWidget(_hallOfFameHarness(_semester(2)));

    expect(find.text('2024 여름'), findsOneWidget);
    expect(find.text('2024 가을'), findsNothing);
  });

  testWidgets('HallOfFameControl renders winter for semester code 4', (
    tester,
  ) async {
    await tester.pumpWidget(_hallOfFameHarness(_semester(4)));

    expect(find.text('2024 겨울'), findsOneWidget);
    expect(find.text('2024 가을'), findsNothing);
  });

  testWidgets('HallOfFameControl preserves spring and fall labels', (
    tester,
  ) async {
    for (final entry in const {1: '봄', 3: '가을'}.entries) {
      await tester.pumpWidget(_hallOfFameHarness(_semester(entry.key)));
      expect(find.text('2024 ${entry.value}'), findsOneWidget);
    }
  });

  testWidgets('CourseDetailPage includes summer and winter lecture history', (
    tester,
  ) async {
    final lectures = [
      _lecture(2, id: 2, classTitle: 'Summer class'),
      _lecture(4, id: 4, classTitle: 'Winter class'),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CourseDetailModel>.value(
            value: _CourseDetailModel(lectures),
          ),
          ChangeNotifierProvider<InfoModel>.value(
            value: _InfoModel(years: const {2024}),
          ),
        ],
        child: MaterialApp(home: CourseDetailPage()),
      ),
    );

    expect(find.textContaining('Summer class'), findsOneWidget);
    expect(find.textContaining('Winter class'), findsOneWidget);
  });

  testWidgets('ReviewBlock renders all known season labels', (tester) async {
    for (final entry in const {1: '봄', 2: '여름', 3: '가을', 4: '겨울'}.entries) {
      await tester.pumpWidget(
        MaterialApp(home: ReviewBlock(review: _review(entry.key))),
      );

      expect(
        find.textContaining(entry.value, findRichText: true),
        findsOneWidget,
      );
    }
  });

  testWidgets('unknown season is not rendered as fall or allowed to throw', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Builder(builder: (_) => Text(_semester(9).title)),
            ReviewBlock(review: _review(9)),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('가을', findRichText: true), findsNothing);
  });

  testWidgets('MyReviewPage renders all known season labels', (tester) async {
    final lectures = [
      _lecture(1, id: 1),
      _lecture(2, id: 2),
      _lecture(3, id: 3),
      _lecture(4, id: 4),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider<InfoModel>.value(
        value: _InfoModel(user: _user(lectures)),
        child: const MaterialApp(home: MyReviewPage()),
      ),
    );

    for (final label in const ['봄', '여름', '가을', '겨울']) {
      expect(find.text('2024 $label'), findsOneWidget);
    }
  });
}

Semester _semester(int code) {
  return Semester(
    year: 2024,
    semester: code,
    beginning: DateTime(2024),
    end: DateTime(2025),
  );
}

Lecture _lecture(int semester, {required int id, String classTitle = ''}) {
  return Lecture.fromJson({
    ...SampleLecture.shared.toJson(),
    'id': id,
    'year': 2024,
    'semester': semester,
    'class_title': classTitle,
  });
}

NestedLecture _nestedLecture(int semester) {
  return NestedLecture.fromJson({
    ...SampleLecture.nested.toJson(),
    'year': 2024,
    'semester': semester,
  });
}

Review _review(int semester) {
  return Review(
    id: semester,
    course: SampleCourse.nested,
    lecture: _nestedLecture(semester),
    content: 'review',
    like: 0,
    isDeleted: 0,
    grade: 0,
    load: 0,
    speech: 0,
    userspecificIsLiked: false,
  );
}

User _user(List<Lecture> lectures) {
  return User(
    id: 1,
    email: '',
    studentId: '',
    firstName: '',
    lastName: '',
    majors: [],
    departments: [],
    myTimetableLectures: [],
    reviewWritableLectures: lectures,
    reviews: [],
  );
}

Widget _hallOfFameHarness(Semester semester) {
  return ChangeNotifierProvider<InfoModel>.value(
    value: _InfoModel(semesters: [semester]),
    child: MaterialApp(
      home: Scaffold(
        body: HallOfFameControl(selectedSemester: semester, onChanged: (_) {}),
      ),
    ),
  );
}

class _InfoModel extends InfoModel {
  _InfoModel({User? user, List<Semester>? semesters, Set<int>? years})
    : userValue = user,
      semesterValues = semesters,
      yearValues = years,
      super(infoRepository: InfoRepository(Dio()), forTest: true);

  final User? userValue;
  final List<Semester>? semesterValues;
  final Set<int>? yearValues;

  @override
  User get user => userValue ?? super.user;

  @override
  List<Semester> get semesters => semesterValues ?? super.semesters;

  @override
  Set<int> get years => yearValues ?? super.years;
}

class _CourseDetailModel extends CourseDetailModel {
  _CourseDetailModel(this.lectureValues)
    : super(
        CourseRepository(Dio()),
        LectureRepository(Dio()),
        ReviewRepository(Dio()),
      );

  final List<Lecture> lectureValues;

  @override
  bool get hasData => true;

  @override
  Course get course => SampleCourse.shared;

  @override
  String get selectedFilter => 'ALL';

  @override
  Lecture? get selectedLecture => null;

  @override
  List<Lecture> get lectures => lectureValues;

  @override
  List<Professor> get professors => SampleCourse.professors;

  @override
  List<Review> get reviews => const [];
}
