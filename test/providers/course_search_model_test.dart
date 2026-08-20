import "dart:async";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/models/course.dart";
import "package:otlplus/models/professor.dart";
import "package:otlplus/providers/course_search_model.dart";
import "package:otlplus/repositories/course_repository.dart";
import "package:otlplus/repositories/department_repository.dart";

class ControlledCourseRepository extends CourseRepository {
  ControlledCourseRepository() : super(Dio());

  final queries = <CourseSearchQuery>[];
  final requests = <Completer<CourseSearchResult>>[];

  @override
  Future<CourseSearchResult> search(CourseSearchQuery query) {
    queries.add(query);
    final request = Completer<CourseSearchResult>();
    requests.add(request);
    return request.future;
  }
}

class RecordingDepartmentRepository extends DepartmentRepository {
  RecordingDepartmentRepository(this.resolvedIds) : super(Dio());

  final List<int> resolvedIds;
  final resolvedCodes = <List<String>>[];

  @override
  Future<List<int>> resolveFilterCodes(Iterable<String> filterCodes) async {
    final codes = filterCodes.toList(growable: false);
    resolvedCodes.add(codes);
    return codes.isEmpty ? const <int>[] : resolvedIds;
  }
}

void main() {
  late ControlledCourseRepository courseRepository;
  late RecordingDepartmentRepository departmentRepository;
  late CourseSearchModel model;

  setUp(() {
    courseRepository = ControlledCourseRepository();
    departmentRepository = RecordingDepartmentRepository(<int>[3844, 4299]);
    model = CourseSearchModel(courseRepository, departmentRepository);
  });

  test("maps selected legacy filters to a v2 repository query", () async {
    model.setSearchText("robot");
    model.setCourseFilterSelected("departments", "MSB", true);
    model.setCourseFilterSelected("types", "BR", true);
    model.setCourseFilterSelected("levels", "200", true);
    model.setCourseFilterSelected("terms", "ALL", false);
    model.setCourseFilterSelected("terms", "3", true);

    final search = model.courseSearch(order: "RAT");
    await Future<void>.delayed(Duration.zero);

    expect(departmentRepository.resolvedCodes, <List<String>>[
      <String>["MSB"],
    ]);
    expect(courseRepository.queries, hasLength(1));
    final query = courseRepository.queries.single;
    expect(query.keyword, "robot");
    expect(query.departments, <int>[3844, 4299]);
    expect(query.types, <String>["BR"]);
    expect(query.levels, <int>[200]);
    expect(query.term, 3);
    expect(query.order, "popular");
    expect(model.isLoading, isTrue);
    expect(model.error, isNull);

    courseRepository.requests.single.complete(_result(_course(1)));
    expect(await search, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(model.isLoading, isFalse);
    expect(model.courses, <Course>[_course(1)]);
  });

  test("maps type filter labels to their v2 codes", () async {
    const expectedCodes = <String, String>{
      "type.br": "BR",
      "type.be": "BE",
      "type.mr": "MR",
      "type.me": "ME",
      "type.mgc": "MGC",
      "type.hse": "HSE",
      "type.gr": "GR",
      "type.eg": "EG",
      "type.oe": "OE",
    };

    for (final entry in expectedCodes.entries) {
      final localCourses = ControlledCourseRepository();
      final localDepartments = RecordingDepartmentRepository(const <int>[]);
      final localModel = CourseSearchModel(localCourses, localDepartments);
      final option = localModel.courseFilter["types"]!.options
          .expand((row) => row)
          .singleWhere((candidate) => candidate.label == entry.key);
      localModel.setCourseFilterSelected("types", option.code, true);

      final search = localModel.courseSearch();
      await Future<void>.delayed(Duration.zero);
      expect(localCourses.queries.single.types, <String>[entry.value]);
      localCourses.requests.single.complete(
        _result(_course(entry.value.hashCode)),
      );
      await search;
      await Future<void>.delayed(Duration.zero);
    }
  });

  test("maps ETC filters and defaults to course-code order", () async {
    model.setCourseFilterSelected("types", "ETC", true);
    model.setCourseFilterSelected("levels", "ETC", true);

    final search = model.courseSearch();
    await Future<void>.delayed(Duration.zero);

    final query = courseRepository.queries.single;
    expect(query.types, isEmpty);
    expect(query.levels, <int>[500, 600, 700, 800, 900]);
    expect(query.term, isNull);
    expect(query.order, "code");

    courseRepository.requests.single.complete(_result(_course(1)));
    await search;
    await Future<void>.delayed(Duration.zero);
  });

  test("does not search with only unsupported type ETC", () async {
    model.setCourseFilterSelected("types", "ETC", true);

    expect(await model.courseSearch(), isFalse);
    expect(courseRepository.queries, isEmpty);
  });

  test("maps every supported term to its v2 integer", () async {
    for (final term in <int>[1, 2, 3]) {
      final localCourses = ControlledCourseRepository();
      final localDepartments = RecordingDepartmentRepository(const <int>[]);
      final localModel = CourseSearchModel(localCourses, localDepartments);
      localModel.setCourseFilterSelected("terms", "ALL", false);
      localModel.setCourseFilterSelected("terms", term.toString(), true);

      final search = localModel.courseSearch();
      await Future<void>.delayed(Duration.zero);
      expect(localCourses.queries.single.term, term);
      expect(localCourses.queries.single.order, "code");
      localCourses.requests.single.complete(_result(_course(term)));
      await search;
      await Future<void>.delayed(Duration.zero);
    }
  });

  test("exposes plain summary data without presentation objects", () {
    model.setSearchText("robot");
    model.setCourseFilterSelected("types", "BR", true);
    model.setCourseFilterSelected("terms", "ALL", false);
    model.setCourseFilterSelected("terms", "2", true);

    expect(model.searchText, "robot");
    expect(model.selectedFilterLabelKeys, <String>["type.br", "term.2_years"]);

    model.resetCourseFilter();
    expect(model.searchText, isEmpty);
    expect(model.selectedFilterLabelKeys, isEmpty);
  });

  test("maps unsupported legacy rating dimensions to v2 popular", () async {
    for (final order in <String>["RAT", "GRA", "LOA", "SPE"]) {
      model.setSearchText(order);
      final search = model.courseSearch(order: order);
      await Future<void>.delayed(Duration.zero);
      expect(courseRepository.queries.last.order, "popular", reason: order);
      courseRepository.requests.last.complete(_result(_course(order.hashCode)));
      await search;
      await Future<void>.delayed(Duration.zero);
    }
  });

  test("latest query wins when an older response completes last", () async {
    model.setSearchText("old");
    final oldSearch = model.courseSearch();
    await Future<void>.delayed(Duration.zero);

    model.setSearchText("new");
    final newSearch = model.courseSearch();
    await Future<void>.delayed(Duration.zero);

    courseRepository.requests[1].complete(_result(_course(2)));
    expect(await newSearch, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(model.courses?.single.id, 2);
    expect(model.isLoading, isFalse);

    courseRepository.requests[0].complete(_result(_course(1)));
    expect(await oldSearch, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(model.courses?.single.id, 2);
    expect(model.isLoading, isFalse);
    expect(model.error, isNull);
  });

  test("exposes the latest request error and clears loading", () async {
    model.setSearchText("failure");
    final search = model.courseSearch();
    await Future<void>.delayed(Duration.zero);

    final failure = StateError("search failed");
    courseRepository.requests.single.completeError(failure);

    expect(await search, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(model.error, same(failure));
    expect(model.isLoading, isFalse);
    expect(model.courses, isNull);
  });

  test("does not search without text or multi-select filters", () async {
    expect(await model.courseSearch(), isFalse);
    expect(courseRepository.queries, isEmpty);
    expect(departmentRepository.resolvedCodes, isEmpty);
  });
}

CourseSearchResult _result(Course course) {
  return CourseSearchResult(courses: <Course>[course], totalCount: 1);
}

Course _course(int id) {
  return Course(
    id: id,
    oldCode: "TEST.$id",
    type: "Type",
    typeEn: "Type",
    title: "Course $id",
    titleEn: "Course $id",
    summary: "",
    reviewTotalWeight: 0,
    professors: <Professor>[],
    grade: 0,
    load: 0,
    speech: 0,
    userspecificIsRead: false,
  );
}
