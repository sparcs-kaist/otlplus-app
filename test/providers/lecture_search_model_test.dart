import "dart:async";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/models/semester.dart";
import "package:otlplus/providers/lecture_search_model.dart";
import "package:otlplus/repositories/department_repository.dart";
import "package:otlplus/repositories/lecture_repository.dart";

import "../utils/samples.dart";

class _FakeLectureRepository extends LectureRepository {
  _FakeLectureRepository() : super(Dio());

  final searched = Completer<void>();
  LectureSearchQuery? query;

  @override
  Future<List<Lecture>> search(LectureSearchQuery query) async {
    this.query = query;
    searched.complete();
    return <Lecture>[SampleLecture.shared];
  }
}

class _FakeDepartmentRepository extends DepartmentRepository {
  _FakeDepartmentRepository() : super(Dio());

  List<String> resolvedCodes = const <String>[];

  @override
  Future<List<int>> resolveFilterCodes(Iterable<String> filterCodes) async {
    resolvedCodes = filterCodes.toList(growable: false);
    return const <int>[623];
  }
}

void main() {
  test(
    "lecture search resolves legacy filters through v2 repositories",
    () async {
      final lectureRepository = _FakeLectureRepository();
      final departmentRepository = _FakeDepartmentRepository();
      final model = LectureSearchModel(lectureRepository, departmentRepository);
      final semester = Semester(
        year: 2026,
        semester: 1,
        beginning: DateTime(2026),
        end: DateTime(2027),
      );

      model.setLectureSearchText("algorithm");
      model.setLectureFilterSelected("departments", "HSS", true);
      model.setLectureFilterSelected("types", "BR", true);
      model.setLectureFilterSelected("levels", "300", true);

      expect(await model.lectureSearch(semester), isTrue);
      await lectureRepository.searched.future;
      await Future<void>.delayed(Duration.zero);

      expect(departmentRepository.resolvedCodes, <String>["HSS"]);
      expect(lectureRepository.query?.year, 2026);
      expect(lectureRepository.query?.semester, 1);
      expect(lectureRepository.query?.keyword, "algorithm");
      expect(lectureRepository.query?.departments, <int>[623]);
      expect(lectureRepository.query?.types, <String>["BR"]);
      expect(lectureRepository.query?.levels, <int>[300]);
      expect(model.lectures, <List<Lecture>>[
        <Lecture>[SampleLecture.shared],
      ]);
      expect(model.isSearching, isFalse);
    },
  );

  test("lecture search rejects an empty query without loading", () async {
    final lectureRepository = _FakeLectureRepository();
    final model = LectureSearchModel(
      lectureRepository,
      _FakeDepartmentRepository(),
    );
    final semester = Semester(
      year: 2026,
      semester: 1,
      beginning: DateTime(2026),
      end: DateTime(2027),
    );

    expect(await model.lectureSearch(semester), isFalse);
    expect(lectureRepository.searched.isCompleted, isFalse);
  });
}
