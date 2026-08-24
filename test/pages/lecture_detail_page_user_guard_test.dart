import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/widgets/review_block.dart';
import 'package:otlplus/widgets/review_write_block.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/samples.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'lecture detail renders reviews without review write block when user is null',
    (tester) async {
      _useLargeViewport(tester);
      final lecture = SampleLecture.shared;

      await tester.pumpWidget(
        _harness(
          infoModel: _InfoModel(),
          detailModel: _LectureDetailModel(lecture, [
            _review('public lecture review'),
          ]),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ReviewWriteBlock), findsNothing);
      expect(find.byType(ReviewBlock), findsWidgets);
    },
  );

  testWidgets('lecture detail shows review write block when user is loaded', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final lecture = SampleLecture.shared;

    await tester.pumpWidget(
      _harness(
        infoModel: _InfoModel(userValue: _user([lecture])),
        detailModel: _LectureDetailModel(lecture, [
          _review('public lecture review'),
        ]),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ReviewWriteBlock), findsOneWidget);
  });
}

void _useLargeViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 2400);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Widget _harness({
  required InfoModel infoModel,
  required LectureDetailModel detailModel,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LectureDetailModel>.value(value: detailModel),
      ChangeNotifierProvider<InfoModel>.value(value: infoModel),
    ],
    child: EasyLocalization(
      supportedLocales: const [Locale('ko')],
      path: 'assets/translations',
      child: MaterialApp(home: LectureDetailPage()),
    ),
  );
}

Review _review(String content) {
  return Review(
    id: 1,
    course: SampleCourse.nested,
    lecture: SampleLecture.nested,
    content: content,
    like: 0,
    isDeleted: 0,
    grade: 3,
    load: 3,
    speech: 3,
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

class _InfoModel extends InfoModel {
  _InfoModel({this.userValue}) : super();

  final User? userValue;

  @override
  User get user => userValue ?? super.user;

  @override
  User? get userOrNull => userValue;

  @override
  List<Semester> get semesters => const <Semester>[];

  @override
  Set<int> get years => <int>{SampleLecture.year};
}

class _LectureDetailModel extends LectureDetailModel {
  _LectureDetailModel(this.lectureValue, this.reviewValues);

  final Lecture lectureValue;
  final List<Review> reviewValues;

  @override
  bool get hasData => true;

  @override
  bool get loadFailed => false;

  @override
  bool get isUpdateEnabled => false;

  @override
  Lecture get lecture => lectureValue;

  @override
  List<Review> get reviews => reviewValues;
}
