import "dart:convert";
import "dart:io";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/enums.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/models/review.dart";
import "package:otlplus/pages/lecture_detail_page.dart";
import "package:otlplus/providers/course_detail_model.dart";
import "package:otlplus/providers/info_model.dart";
import "package:otlplus/providers/lecture_detail_model.dart";
import "package:otlplus/providers/timetable_model.dart";
import "package:otlplus/widgets/lecture_group_block_row.dart";
import "package:otlplus/widgets/otl_dialog.dart";
import "package:otlplus/widgets/responsive_button.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";

class RecordingTimetableModel extends TimetableModel {
  RecordingTimetableModel() : super(forTest: true) {
    setIndex(1);
  }

  List<Lecture> overlaps = <Lecture>[];
  final replaceOverlapCalls = <bool>[];

  @override
  List<Lecture> overlappingLectures(Lecture lecture) =>
      List<Lecture>.unmodifiable(overlaps);

  @override
  Future<TimetableAddResult> addLecture({
    required Lecture lecture,
    bool replaceOverlaps = false,
  }) async {
    replaceOverlapCalls.add(replaceOverlaps);
    return TimetableAddResult.added;
  }
}

class LoadedLectureDetailModel extends LectureDetailModel {
  LoadedLectureDetailModel(this.loadedLecture);

  final Lecture loadedLecture;

  @override
  bool get hasData => true;

  @override
  bool get loadFailed => false;

  @override
  bool get isUpdateEnabled => true;

  @override
  Lecture get lecture => loadedLecture;

  @override
  List<Review> get reviews => const <Review>[];
}

void main() {
  late Lecture lecture;
  late Lecture overlappingLecture;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    final detail =
        jsonDecode(
              await File(
                "test/fixtures/v2/timetable_detail.json",
              ).readAsString(),
            )
            as Map<String, dynamic>;
    final rawLecture = Map<String, dynamic>.from(
      (detail["lectures"] as List<dynamic>).single as Map<String, dynamic>,
    );
    lecture = Lecture.fromV2Json(rawLecture, year: 2026, semester: 3);
    overlappingLecture = Lecture.fromV2Json(
      <String, dynamic>{...rawLecture, "id": lecture.id + 1},
      year: 2026,
      semester: 3,
    );
  });

  testWidgets(
    "LectureDetailPage waits for no-overlap confirmation before mutation",
    (tester) async {
      final timetableModel = RecordingTimetableModel();
      final detailModel = LoadedLectureDetailModel(lecture);

      await tester.pumpWidget(
        _localizedApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<TimetableModel>.value(
                value: timetableModel,
              ),
              ChangeNotifierProvider<LectureDetailModel>.value(
                value: detailModel,
              ),
              ChangeNotifierProvider<InfoModel>.value(
                value: InfoModel(forTest: true),
              ),
              ChangeNotifierProvider<CourseDetailModel>.value(
                value: CourseDetailModel(),
              ),
            ],
            child: LectureDetailPage(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconTextButton &&
              widget.icon == Icons.add_circle_outline_rounded,
        ),
      );
      await tester.pumpAndSettle();

      expect(timetableModel.replaceOverlapCalls, isEmpty);
      final dialog = tester.widget<OTLDialog>(find.byType(OTLDialog));
      expect(dialog.type, OTLDialogType.addLectureWithTab);

      dialog.onTapPos!();
      await tester.pump();

      expect(timetableModel.replaceOverlapCalls, <bool>[false]);
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    "LectureGroupBlockRow waits for overlap confirmation before replacement",
    (tester) async {
      final timetableModel = RecordingTimetableModel()
        ..overlaps = <Lecture>[overlappingLecture];

      await tester.pumpWidget(
        _localizedApp(
          ChangeNotifierProvider<TimetableModel>.value(
            value: timetableModel,
            child: Scaffold(body: LectureGroupBlockRow(lecture: lecture)),
          ),
        ),
      );
      await tester.tap(find.byType(LectureGroupBlockRow));
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconTextButton && widget.icon == "assets/icons/add.svg",
        ),
      );
      await tester.pumpAndSettle();

      expect(timetableModel.replaceOverlapCalls, isEmpty);
      final dialog = tester.widget<OTLDialog>(find.byType(OTLDialog));
      expect(dialog.type, OTLDialogType.addOverlappingLecture);

      dialog.onTapPos!();
      await tester.pump();

      expect(timetableModel.replaceOverlapCalls, <bool>[true]);
      await tester.pump(const Duration(seconds: 1));
    },
  );
}

Widget _localizedApp(Widget home) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale("ko")],
    path: "assets/translations",
    child: MaterialApp(home: home),
  );
}
