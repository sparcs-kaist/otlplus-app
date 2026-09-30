import 'dart:convert';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:dio/dio.dart';
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
import 'package:otlplus/repositories/course_repository.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/repositories/lecture_repository.dart';
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
  for (final success in [true, false]) {
    testWidgets(
      'iOS syllabus opens the system browser (success=$success)',
      (tester) async {
        _useLargeViewport(tester);
        final originalLauncher = UrlLauncherPlatform.instance;
        final launcher = _SyllabusLauncher(success);
        UrlLauncherPlatform.instance = launcher;
        addTearDown(() {
          UrlLauncherPlatform.instance = originalLauncher;
        });
        final lecture = SampleLecture.shared;
        await tester.pumpWidget(
          _harness(
            infoModel: _InfoModel(),
            detailModel: _LectureDetailModel(lecture, []),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('실라버스'));
        await tester.pump(const Duration(seconds: 1));
        final uri = Uri.parse(launcher.url!);
        expect(uri.host, 'erp.kaist.ac.kr');
        expect(uri.queryParameters['link'], 'estblSubjt');
        expect(
          jsonDecode(utf8.decode(base64Decode(uri.queryParameters['params']!))),
          {
            'syy': lecture.year.toString(),
            'smtDivCd': lecture.semester.toString(),
            'subjtCd': lecture.oldCode,
          },
        );
        expect(launcher.options!.mode, PreferredLaunchMode.externalApplication);
        if (!success) {
          expect(find.text('실라버스를 열지 못했습니다. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({TargetPlatform.iOS}),
    );
  }
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
  _InfoModel({this.userValue}) : super(infoRepository: InfoRepository(Dio()));

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
  _LectureDetailModel(this.lectureValue, this.reviewValues)
    : super(
        CourseRepository(Dio()),
        LectureRepository(Dio()),
        ReviewRepository(Dio()),
      );

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

class _SyllabusLauncher extends UrlLauncherPlatform {
  _SyllabusLauncher(this.success);
  final bool success;
  String? url;
  LaunchOptions? options;
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    this.options = options;
    return success;
  }
}
