import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/widgets/course_block.dart';
import 'package:otlplus/widgets/dropdown.dart';
import 'package:otlplus/widgets/expandable_text.dart';
import 'package:otlplus/widgets/lecture_group_block.dart';
import 'package:otlplus/widgets/lecture_group_block_row.dart';
import 'package:otlplus/widgets/lecture_group_simple_block.dart';
import 'package:otlplus/widgets/lecture_search.dart';
import 'package:otlplus/widgets/lecture_simple_block.dart';
import 'package:otlplus/widgets/review_write_block.dart';
import 'package:otlplus/widgets/semester_picker.dart';
import 'package:otlplus/widgets/timetable.dart';
import 'package:otlplus/widgets/timetable_block.dart';
import 'package:otlplus/widgets/timetable_summary.dart';
import 'package:otlplus/widgets/timetable_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/extensions.dart';
import '../utils/samples.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('pump CourseBlock', (WidgetTester tester) async {
    await tester.pumpWidget(CourseBlock(course: SampleCourse.shared).material);
  });

  testWidgets('pump Dropdown', (WidgetTester tester) async {
    await tester.pumpWidget(
      Dropdown(
        customButton: Text('Dropdown'),
        items: [ItemData(value: 1, text: 'Item 1')],
        onChanged: (_) {},
      ).scaffold,
    );
  });

  testWidgets('pump ExpandableText', (WidgetTester tester) async {
    await tester.pumpWidget(ExpandableText('text').material);
  });

  testWidgets('pump LectureGroupBlockRow', (WidgetTester tester) async {
    await tester.pumpWidget(
      LectureGroupBlockRow(
        lecture: SampleLecture.shared,
      ).materialAndNotifier(TimetableModel(forTest: true)),
    );
  });

  testWidgets('pump LectureGroupBlock', (WidgetTester tester) async {
    await tester.pumpWidget(
      LectureGroupBlock(
        lectures: [SampleLecture.shared],
        onLongPress: (_) {
          return;
        },
      ).materialAndNotifier(TimetableModel(forTest: true)),
    );
  });

  testWidgets('pump LectureGroupSimpleBlock', (WidgetTester tester) async {
    await tester.pumpWidget(
      LectureGroupSimpleBlock(lectures: [], semester: 1).material,
    );
  });

  testWidgets('pump LectureSearch', (WidgetTester tester) async {
    await tester.pumpWidget(
      LectureSearch().scaffoldAndNotifier(LectureSearchModel()),
    );
  });

  testWidgets('pump LectureSimpleBlock', (WidgetTester tester) async {
    await tester.pumpWidget(
      LectureSimpleBlock(lecture: SampleLecture.shared).material,
    );
  });

  testWidgets('pump ReviewWriteBlock', (WidgetTester tester) async {
    await tester.pumpWidget(
      ReviewWriteBlock(lecture: SampleLecture.shared).scaffold,
    );
  });

  testWidgets('pump SemesterPicker', (WidgetTester tester) async {
    await tester.pumpWidget(
      SemesterPicker(
        onSemesterChanged: () => null,
      ).scaffoldAndNotifier(TimetableModel(forTest: true)),
    );
  });

  testWidgets('pump TimetableBlock', (WidgetTester tester) async {
    await tester.pumpWidget(
      TimetableBlock(lecture: SampleLecture.shared).scaffold,
    );
  });

  testWidgets('pump TimetableSummary', (WidgetTester tester) async {
    tester.pumpWidget(
      TimetableSummary().scaffoldAndNotifier(TimetableModel(forTest: true)),
    );
  });

  testWidgets('pump TimetableTabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      TimetableTabs(
        length: 1,
        onTap: (_) {},
        onCopyTap: () {},
        onDeleteTap: (_) {},
        onExportTap: (_) {},
      ).scaffold,
    );
  });

  testWidgets('pump Timetable', (WidgetTester tester) async {
    await tester.pumpWidget(
      Timetable(
        lectures: [],
        builder: (lecture, _, __) => TimetableBlock(lecture: lecture),
      ).inScrollView.material,
    );
  });

  testWidgets('pump TodayTimetable', (WidgetTester tester) async {
    //   await tester.pumpWidget(TodayTimetable(
    //           lectures: [SampleLecture.shared],
    //           builder: (lecture, _) {
    //             return TimetableBlock(lecture: lecture);
    //           },
    //           now: DateTime.now())
    //       .material);
  });
}
