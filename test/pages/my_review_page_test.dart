import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/nested_lecture.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/pages/my_review_page.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/widgets/lecture_simple_block.dart';
import 'package:provider/provider.dart';

import '../utils/samples.dart';

void main() {
  testWidgets('orders semester groups by descending year then season code', (
    tester,
  ) async {
    final lectures = <Lecture>[
      _lecture(id: 1, year: 2024, semester: 4),
      _lecture(id: 2, year: 2025, semester: 1),
      _lecture(id: 3, year: 2025, semester: 4),
    ];

    await _pumpPage(tester, _user(lectures: lectures));

    final headers = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .where(
          (text) =>
              const <String>{'2025 겨울', '2025 봄', '2024 겨울'}.contains(text),
        )
        .toList();

    expect(headers, <String?>['2025 겨울', '2025 봄', '2024 겨울']);
  });

  testWidgets('renders one header text for each semester group', (
    tester,
  ) async {
    final lectures = <Lecture>[
      _lecture(id: 1, year: 2025, semester: 3),
      _lecture(id: 2, year: 2025, semester: 3),
      _lecture(id: 3, year: 2024, semester: 1),
    ];

    await _pumpPage(tester, _user(lectures: lectures));

    expect(find.text('2025 가을'), findsOneWidget);
    expect(find.text('2024 봄'), findsOneWidget);
  });

  testWidgets(
    'pairs lectures two per IntrinsicHeight row and fills an odd trailing cell',
    (tester) async {
      final lectures = List<Lecture>.generate(
        5,
        (index) => _lecture(id: index + 1, year: 2025, semester: 3),
      );

      await _pumpPage(tester, _user(lectures: lectures));

      final lectureRows = tester
          .widgetList<Row>(find.byType(Row))
          .where((row) => _lectureBlocksIn(row).isNotEmpty)
          .toList();

      expect(lectureRows, hasLength(3));
      expect(
        lectureRows.map(
          (row) =>
              _lectureBlocksIn(row).map((block) => block.lecture.id).toList(),
        ),
        <List<int>>[
          <int>[1, 2],
          <int>[3, 4],
          <int>[5],
        ],
      );

      for (final row in lectureRows.take(2)) {
        expect(
          find.ancestor(
            of: find.byWidget(row),
            matching: find.byType(IntrinsicHeight),
          ),
          findsOneWidget,
        );
      }

      final oddRow = lectureRows.last;
      expect(oddRow.children, hasLength(2));
      expect(oddRow.children[0], isA<Expanded>());
      expect((oddRow.children[0] as Expanded).child, isA<LectureSimpleBlock>());
      expect(oddRow.children[1], isA<Expanded>());
      expect((oddRow.children[1] as Expanded).child, isA<SizedBox>());
    },
  );

  testWidgets(
    'renders a blank body when there are no review-writable lectures',
    (tester) async {
      await _pumpPage(tester, _user(lectures: const <Lecture>[]));

      final body = find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == OTLColor.grayF,
      );

      expect(body, findsOneWidget);
      expect(
        find.descendant(of: body, matching: find.byType(Text)),
        findsNothing,
      );
      expect(find.byType(LectureSimpleBlock), findsNothing);
    },
  );

  testWidgets('shows review-taken state only for matching lecture ids', (
    tester,
  ) async {
    final reviewedLecture = _lecture(id: 1, year: 2025, semester: 3);
    final writableLecture = _lecture(id: 2, year: 2025, semester: 3);

    await _pumpPage(
      tester,
      _user(
        lectures: <Lecture>[reviewedLecture, writableLecture],
        reviews: <Review>[_reviewFor(reviewedLecture)],
      ),
    );

    final blocks = tester.widgetList<LectureSimpleBlock>(
      find.byType(LectureSimpleBlock),
    );
    final reviewedBlock = blocks.singleWhere(
      (block) => block.lecture.id == reviewedLecture.id,
    );
    final writableBlock = blocks.singleWhere(
      (block) => block.lecture.id == writableLecture.id,
    );

    expect(reviewedBlock.hasReview, isTrue);
    expect(writableBlock.hasReview, isFalse);
  });
}

Future<void> _pumpPage(WidgetTester tester, User user) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<InfoModel>.value(
      value: _InfoModel(user),
      child: const MaterialApp(home: MyReviewPage()),
    ),
  );
}

List<LectureSimpleBlock> _lectureBlocksIn(Row row) {
  return row.children
      .whereType<Expanded>()
      .map((expanded) => expanded.child)
      .whereType<LectureSimpleBlock>()
      .toList();
}

Lecture _lecture({required int id, required int year, required int semester}) {
  return Lecture.fromJson(<String, dynamic>{
    ...SampleLecture.shared.toJson(),
    'id': id,
    'title': 'Lecture $id',
    'title_en': 'Lecture $id',
    'old_code': 'CODE$id',
    'year': year,
    'semester': semester,
  });
}

Review _reviewFor(Lecture lecture) {
  return Review(
    id: lecture.id,
    course: SampleCourse.nested,
    lecture: NestedLecture.fromJson(lecture.toJson()),
    content: 'review',
    like: 0,
    isDeleted: false,
    grade: 0,
    load: 0,
    speech: 0,
    userspecificIsLiked: false,
  );
}

User _user({required List<Lecture> lectures, List<Review> reviews = const []}) {
  return User(
    id: 1,
    email: '',
    studentId: '',
    firstName: '',
    lastName: '',
    majors: const [],
    departments: const [],
    myTimetableLectures: const [],
    reviewWritableLectures: lectures,
    reviews: reviews,
  );
}

class _InfoModel extends InfoModel {
  _InfoModel(this.userValue)
    : super(infoRepository: InfoRepository(Dio()), forTest: true);

  final User userValue;

  @override
  User get user => userValue;
}
