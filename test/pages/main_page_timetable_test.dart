import "dart:convert";
import "dart:io";

import "package:dio/dio.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/models/semester.dart";
import "package:otlplus/models/timetable.dart";
import "package:otlplus/models/user.dart";
import "package:otlplus/pages/main_page.dart";
import "package:otlplus/providers/info_model.dart";
import "package:otlplus/providers/timetable_model.dart";
import "package:otlplus/repositories/info_repository.dart";
import "package:otlplus/repositories/timetable_repository.dart";
import "package:otlplus/widgets/timetable_block.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";

class MainPageTimetableRepository extends TimetableRepository {
  MainPageTimetableRepository({required this.primary, required this.collection})
    : super(Dio());

  final Timetable primary;
  final TimetableCollection collection;

  @override
  Future<Timetable> fetchMyTimetable(int year, int semester) async => primary;

  @override
  Future<TimetableCollection> fetchBySemester(int year, int semester) async =>
      collection;
}

class LoadedInfoModel extends InfoModel {
  LoadedInfoModel(this.loadedUser, this.loadedSemester)
    : super(infoRepository: InfoRepository(Dio()), forTest: true);

  final User loadedUser;
  final Semester loadedSemester;

  @override
  bool get hasData => true;

  @override
  bool get hasError => false;

  @override
  User get user => loadedUser;

  @override
  List<Semester> get semesters => <Semester>[loadedSemester];

  @override
  Map<String, dynamic>? get currentSchedule => null;
}

void main() {
  late Map<String, dynamic> detailFixture;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    WidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("plugins.it_nomads.com/flutter_secure_storage"),
          (_) async => null,
        );
    await EasyLocalization.ensureInitialized();
    detailFixture =
        jsonDecode(
              await File(
                "test/fixtures/v2/timetable_detail.json",
              ).readAsString(),
            )
            as Map<String, dynamic>;
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("plugins.it_nomads.com/flutter_secure_storage"),
          null,
        );
  });

  testWidgets("MainPage renders the primary my-timetable, not server index 0", (
    tester,
  ) async {
    final primaryJson = _lectureJson(
      detailFixture,
      id: 100,
      name: "Primary lecture",
    );
    final editableJson = _lectureJson(
      detailFixture,
      id: 200,
      name: "Editable lecture",
    );
    final semester = Semester(
      year: 2026,
      semester: 3,
      beginning: DateTime(2026, 8, 1),
      end: DateTime(2026, 12, 31),
    );
    final primary = Timetable.fromV2MyTimetable(
      <String, dynamic>{
        "lectures": <Map<String, dynamic>>[primaryJson],
      },
      year: semester.year,
      semester: semester.semester,
    );
    const summary = TimetableListItem(
      id: 7,
      name: "Editable",
      year: 2026,
      semester: 3,
      timeTableOrder: 0,
    );
    final editable = Timetable.fromV2Detail(<String, dynamic>{
      "lectures": <Map<String, dynamic>>[editableJson],
    }, summary: summary);
    final repository = MainPageTimetableRepository(
      primary: primary,
      collection: TimetableCollection(
        summaries: <TimetableListItem>[summary],
        timetables: <Timetable>[editable],
      ),
    );
    final timetableModel = TimetableModel(repository: repository);
    final user = User(
      id: 42,
      email: "test@example.com",
      studentId: "20260001",
      firstName: "Test",
      lastName: "User",
      majors: [],
      departments: [],
      myTimetableLectures: <Lecture>[],
      reviewWritableLectures: <Lecture>[],
      reviews: [],
    );
    await timetableModel
        .loadSemesters(user: user, semesters: <Semester>[semester])
        .timeout(const Duration(seconds: 5));

    await tester
        .pumpWidget(
          EasyLocalization(
            supportedLocales: const <Locale>[Locale("ko")],
            path: "assets/translations",
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<InfoModel>.value(
                  value: LoadedInfoModel(user, semester),
                ),
                ChangeNotifierProvider<TimetableModel>.value(
                  value: timetableModel,
                ),
              ],
              child: MaterialApp(home: MainPage(changeIndex: (_) {})),
            ),
          ),
        )
        .timeout(const Duration(seconds: 5));
    await tester.pump().timeout(const Duration(seconds: 5));

    final renderedLectures = tester
        .widgetList<TimetableBlock>(find.byType(TimetableBlock))
        .map((block) => block.lecture.id)
        .toList();
    expect(renderedLectures, contains(100));
    expect(renderedLectures, isNot(contains(200)));
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _lectureJson(
  Map<String, dynamic> detail, {
  required int id,
  required String name,
}) {
  final lecture = Map<String, dynamic>.from(
    (detail["lectures"] as List<dynamic>).single as Map<String, dynamic>,
  );
  final classtime =
      Map<String, dynamic>.from(
          (lecture["classes"] as List<dynamic>).single as Map<String, dynamic>,
        )
        ..["day"] = DateTime.now().weekday - 1
        ..["begin"] = 900
        ..["end"] = 1000;
  return lecture
    ..["id"] = id
    ..["courseId"] = id
    ..["name"] = name
    ..["classes"] = <Map<String, dynamic>>[classtime];
}
