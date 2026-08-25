import "dart:async";
import "dart:collection";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/enums.dart";
import "package:otlplus/models/classtime.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/models/semester.dart";
import "package:otlplus/models/time.dart";
import "package:otlplus/models/timetable.dart";
import "package:otlplus/models/user.dart";
import "package:otlplus/providers/timetable_model.dart";
import "package:otlplus/repositories/timetable_repository.dart";

class RepositoryUpdateCall {
  const RepositoryUpdateCall(this.summary, this.lectureId, this.action);

  final TimetableListItem summary;
  final int lectureId;
  final TimetableLectureAction action;
}

class FakeTimetableRepository extends TimetableRepository {
  FakeTimetableRepository() : super(Dio());

  final collections = Queue<TimetableCollection>();
  final fetchCalls = <(int, int)>[];
  final myTimetableCalls = <(int, int)>[];
  Timetable myTimetable = Timetable(id: -1, lectures: <Lecture>[]);
  Completer<Timetable>? myTimetableCompleter;
  final createCalls = <({int year, int semester, List<int> lectureIds})>[];
  final updateCalls = <RepositoryUpdateCall>[];
  final deleteCalls = <int>[];
  final lecturesById = <int, Lecture>{};
  final serverTimetables = <int, Timetable>{};
  final createdIds = Queue<int>();
  Object? fetchError;

  @override
  Future<Timetable> fetchMyTimetable(int year, int semester) {
    myTimetableCalls.add((year, semester));
    return myTimetableCompleter?.future ?? Future<Timetable>.value(myTimetable);
  }

  @override
  Future<TimetableCollection> fetchBySemester(int year, int semester) async {
    fetchCalls.add((year, semester));
    final error = fetchError;
    if (error != null) throw error;
    return collections.removeFirst();
  }

  @override
  Future<int> create({
    required int year,
    required int semester,
    required List<int> lectureIds,
  }) async {
    createCalls.add((
      year: year,
      semester: semester,
      lectureIds: List<int>.of(lectureIds),
    ));
    return createdIds.removeFirst();
  }

  @override
  Future<Timetable> updateLecture({
    required TimetableListItem summary,
    required int lectureId,
    required TimetableLectureAction action,
  }) async {
    updateCalls.add(RepositoryUpdateCall(summary, lectureId, action));
    final current = serverTimetables[summary.id]!;
    final lectures = List<Lecture>.of(current.lectures);
    switch (action) {
      case TimetableLectureAction.add:
        lectures.add(lecturesById[lectureId]!);
        break;
      case TimetableLectureAction.delete:
        lectures.removeWhere((lecture) => lecture.id == lectureId);
        break;
    }
    final updated = Timetable(id: summary.id, lectures: lectures);
    serverTimetables[summary.id] = updated;
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    deleteCalls.add(id);
    serverTimetables.remove(id);
  }
}

void main() {
  late FakeTimetableRepository repository;
  late TimetableModel model;
  late Lecture primaryLecture;
  late Lecture firstLecture;
  late Lecture secondLecture;
  late User user;
  late Semester semester;

  setUp(() {
    repository = FakeTimetableRepository();
    model = TimetableModel(repository: repository);
    primaryLecture = _lecture(5, day: 0, begin: 0, end: 1);
    firstLecture = _lecture(10, day: 1, begin: 2, end: 4);
    secondLecture = _lecture(11, day: 2, begin: 4, end: 6);
    user = _user();
    semester = Semester(
      year: 2026,
      semester: Season.fall.code,
      beginning: DateTime(2026, 8, 1),
      end: DateTime(2026, 12, 31),
    );
  });

  test("load fetches primary and editable timetables concurrently", () async {
    final firstSummary = _summary(7, order: 0);
    final secondSummary = _summary(8, order: 1);
    repository.myTimetableCompleter = Completer<Timetable>();
    repository.collections.add(
      TimetableCollection(
        summaries: <TimetableListItem>[firstSummary, secondSummary],
        timetables: <Timetable>[
          Timetable(id: 7, lectures: <Lecture>[firstLecture]),
          Timetable(id: 8, lectures: <Lecture>[secondLecture]),
        ],
      ),
    );

    final load = model.loadSemesters(
      user: user,
      semesters: <Semester>[semester],
    );
    await Future<void>.delayed(Duration.zero);

    expect(model.isLoading, isTrue);
    expect(repository.myTimetableCalls, <(int, int)>[(2026, Season.fall.code)]);
    expect(repository.fetchCalls, <(int, int)>[(2026, Season.fall.code)]);

    repository.myTimetableCompleter!.complete(
      Timetable(id: -1, lectures: <Lecture>[primaryLecture]),
    );
    await load;

    expect(model.isLoading, isFalse);
    expect(model.isLoaded, isTrue);
    expect(model.loadFailed, isFalse);
    expect(model.error, isNull);
    expect(model.summaries.map((summary) => summary.id), <int>[7, 8]);
    expect(model.timetables.map((timetable) => timetable.id), <int>[-1, 7, 8]);
    expect(model.currentTimetable.lectures, <Lecture>[primaryLecture]);
    expect(model.selectedIndex, 0);
  });

  test("load creates an empty server timetable and refetches", () async {
    final createdSummary = _summary(9, order: 0);
    repository.createdIds.add(9);
    repository.collections
      ..add(
        TimetableCollection(
          summaries: <TimetableListItem>[],
          timetables: <Timetable>[],
        ),
      )
      ..add(
        TimetableCollection(
          summaries: <TimetableListItem>[createdSummary],
          timetables: <Timetable>[Timetable(id: 9, lectures: <Lecture>[])],
        ),
      );

    await model.loadSemesters(user: user, semesters: <Semester>[semester]);

    expect(repository.createCalls, hasLength(1));
    expect(repository.createCalls.single.lectureIds, isEmpty);
    expect(repository.fetchCalls, hasLength(2));
    expect(model.timetables.map((timetable) => timetable.id), <int>[-1, 9]);
    expect(model.selectedIndex, 0);
  });

  test(
    "load exposes an explicit error and leaves no invalid selection",
    () async {
      final failure = StateError("load failed");
      repository.fetchError = failure;

      await model.loadSemesters(user: user, semesters: <Semester>[semester]);

      expect(model.isLoading, isFalse);
      expect(model.isLoaded, isFalse);
      expect(model.loadFailed, isTrue);
      expect(model.error, same(failure));
      expect(model.timetables, isEmpty);
      expect(model.selectedIndex, 0);
    },
  );

  test("add patches and replaces the selected timetable detail", () async {
    await _loadOneServerTimetable(
      model,
      repository,
      user,
      semester,
      lectures: <Lecture>[firstLecture],
    );
    repository.lecturesById[secondLecture.id] = secondLecture;
    model.setIndex(1);

    final result = await model.addLecture(lecture: secondLecture);

    expect(result, TimetableAddResult.added);
    expect(repository.updateCalls, hasLength(1));
    expect(repository.updateCalls.single.summary.id, 7);
    expect(repository.updateCalls.single.lectureId, secondLecture.id);
    expect(repository.updateCalls.single.action, TimetableLectureAction.add);
    expect(model.currentTimetable.lectures, <Lecture>[
      firstLecture,
      secondLecture,
    ]);
  });

  test("remove patches and replaces the selected timetable detail", () async {
    await _loadOneServerTimetable(
      model,
      repository,
      user,
      semester,
      lectures: <Lecture>[firstLecture, secondLecture],
    );
    model.setIndex(1);

    expect(await model.removeLecture(lecture: firstLecture), isTrue);

    expect(repository.updateCalls, hasLength(1));
    expect(repository.updateCalls.single.summary.id, 7);
    expect(repository.updateCalls.single.lectureId, firstLecture.id);
    expect(repository.updateCalls.single.action, TimetableLectureAction.delete);
    expect(model.currentTimetable.lectures, <Lecture>[secondLecture]);
  });

  test(
    "overlap returns a typed result without mutating the repository",
    () async {
      final overlapping = _lecture(12, day: 1, begin: 3, end: 5);
      await _loadOneServerTimetable(
        model,
        repository,
        user,
        semester,
        lectures: <Lecture>[firstLecture],
      );
      model.setIndex(1);

      final result = await model.addLecture(lecture: overlapping);

      expect(result, TimetableAddResult.overlap);
      expect(model.overlappingLectures(overlapping), <Lecture>[firstLecture]);
      expect(repository.updateCalls, isEmpty);
      expect(model.currentTimetable.lectures, <Lecture>[firstLecture]);
    },
  );

  test("confirmed overlap removes conflicts before adding", () async {
    final overlapping = _lecture(12, day: 1, begin: 3, end: 5);
    await _loadOneServerTimetable(
      model,
      repository,
      user,
      semester,
      lectures: <Lecture>[firstLecture, secondLecture],
    );
    repository.lecturesById[overlapping.id] = overlapping;
    model.setIndex(1);

    final result = await model.addLecture(
      lecture: overlapping,
      replaceOverlaps: true,
    );

    expect(result, TimetableAddResult.added);
    expect(
      repository.updateCalls.map((call) => (call.lectureId, call.action)),
      <(int, TimetableLectureAction)>[
        (firstLecture.id, TimetableLectureAction.delete),
        (overlapping.id, TimetableLectureAction.add),
      ],
    );
    expect(model.currentTimetable.lectures, <Lecture>[
      secondLecture,
      overlapping,
    ]);
  });

  test("create refetches and selects the created timetable by id", () async {
    final existingSummary = _summary(1, order: 0);
    final createdSummary = _summary(9, order: 1);
    repository.createdIds.add(9);
    repository.collections
      ..add(
        TimetableCollection(
          summaries: <TimetableListItem>[existingSummary],
          timetables: <Timetable>[Timetable(id: 1, lectures: <Lecture>[])],
        ),
      )
      ..add(
        TimetableCollection(
          summaries: <TimetableListItem>[existingSummary, createdSummary],
          timetables: <Timetable>[
            Timetable(id: 1, lectures: <Lecture>[]),
            Timetable(id: 9, lectures: <Lecture>[firstLecture]),
          ],
        ),
      );
    await model.loadSemesters(user: user, semesters: <Semester>[semester]);

    expect(
      await model.createTimetable(lectures: <Lecture>[firstLecture]),
      isTrue,
    );

    expect(repository.createCalls.single.lectureIds, <int>[firstLecture.id]);
    expect(repository.fetchCalls, hasLength(2));
    expect(model.timetables.map((timetable) => timetable.id), <int>[-1, 1, 9]);
    expect(model.currentTimetable.id, 9);
    expect(model.selectedIndex, 2);
  });

  test(
    "first user-created timetable is editable and deletable at index 1",
    () async {
      final firstSummary = _summary(7, order: 0);
      final secondSummary = _summary(8, order: 1);
      repository.collections.add(
        TimetableCollection(
          summaries: <TimetableListItem>[firstSummary, secondSummary],
          timetables: <Timetable>[
            Timetable(id: 7, lectures: <Lecture>[firstLecture]),
            Timetable(id: 8, lectures: <Lecture>[secondLecture]),
          ],
        ),
      );
      repository.serverTimetables[7] = Timetable(
        id: 7,
        lectures: <Lecture>[firstLecture],
      );
      await model.loadSemesters(user: user, semesters: <Semester>[semester]);
      model.setIndex(1);

      expect(await model.deleteTimetable(), isTrue);

      expect(repository.deleteCalls, <int>[7]);
      expect(model.summaries.map((summary) => summary.id), <int>[8]);
      expect(model.timetables.map((timetable) => timetable.id), <int>[-1, 8]);
      expect(model.selectedIndex, 0);
      expect(model.currentTimetable.id, -1);
    },
  );

  test(
    "reload keeps an editable selection valid after server reorder",
    () async {
      await _loadOneServerTimetable(
        model,
        repository,
        user,
        semester,
        lectures: <Lecture>[],
      );
      model.setIndex(1);
      final reorderedSummary = _summary(8, order: 0);
      repository.collections.add(
        TimetableCollection(
          summaries: <TimetableListItem>[reorderedSummary],
          timetables: <Timetable>[Timetable(id: 8, lectures: <Lecture>[])],
        ),
      );

      await model.loadSemesters(user: user, semesters: <Semester>[semester]);

      expect(model.selectedIndex, 1);
      expect(model.currentTimetable.id, 8);
    },
  );

  test("invalid selected indices are ignored", () async {
    await _loadOneServerTimetable(
      model,
      repository,
      user,
      semester,
      lectures: <Lecture>[],
    );

    model.setIndex(-1);
    expect(model.selectedIndex, 0);
    model.setIndex(2);
    expect(model.selectedIndex, 0);
  });
}

Future<void> _loadOneServerTimetable(
  TimetableModel model,
  FakeTimetableRepository repository,
  User user,
  Semester semester, {
  required List<Lecture> lectures,
}) async {
  final editableSummary = _summary(7, order: 0);
  final editableTimetable = Timetable(
    id: 7,
    lectures: List<Lecture>.of(lectures),
  );
  repository.serverTimetables[7] = editableTimetable;
  for (final lecture in lectures) {
    repository.lecturesById[lecture.id] = lecture;
  }
  repository.collections.add(
    TimetableCollection(
      summaries: <TimetableListItem>[editableSummary],
      timetables: <Timetable>[editableTimetable],
    ),
  );
  await model.loadSemesters(user: user, semesters: <Semester>[semester]);
}

TimetableListItem _summary(int id, {required int order}) {
  return TimetableListItem(
    id: id,
    name: "시간표 $id",
    year: 2026,
    semester: Season.fall.code,
    timeTableOrder: order,
  );
}

User _user() {
  return User(
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
}

Lecture _lecture(
  int id, {
  required int day,
  required int begin,
  required int end,
}) {
  return Lecture(
    id: id,
    title: "강의 $id",
    titleEn: "Lecture $id",
    course: id,
    oldCode: "CS$id",
    classNo: "A",
    year: 2026,
    semester: Season.fall.code,
    code: "CS$id",
    department: 1,
    departmentCode: "CS",
    departmentName: "전산학부",
    departmentNameEn: "School of Computing",
    type: "전공선택",
    typeEn: "Major Elective",
    typeIdx: 3,
    limit: 10,
    numPeople: 5,
    isEnglish: false,
    credit: 3,
    creditAu: 0,
    commonTitle: "강의 $id",
    commonTitleEn: "Lecture $id",
    classTitle: "",
    classTitleEn: "",
    reviewTotalWeight: 0,
    professors: [],
    grade: 0,
    load: 0,
    speech: 0,
    classtimes: <Classtime>[
      Classtime(
        buildingCode: "E3",
        classroom: "강의실",
        classroomEn: "Classroom",
        classroomShort: "E3",
        classroomShortEn: "E3",
        roomName: "101",
        day: Weekday.fromCode(day),
        begin: begin,
        end: end,
      ),
    ],
    examtimes: [],
  );
}
