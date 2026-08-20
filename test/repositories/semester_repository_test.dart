import "dart:convert";
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/semester.dart";
import "package:otlplus/repositories/semester_repository.dart";

import "../utils/fake_http.dart";

void main() {
  late FakeHttpAdapter adapter;
  late SemesterRepository repository;

  setUp(() async {
    final semesters =
        jsonDecode(
              await File("test/fixtures/v2/semesters.json").readAsString(),
            )
            as Map<String, dynamic>;
    final current =
        jsonDecode(
              await File(
                "test/fixtures/v2/current_semester.json",
              ).readAsString(),
            )
            as Map<String, dynamic>;
    adapter = FakeHttpAdapter();
    adapter.register("GET", "/$API_V2_SEMESTERS_URL", semesters);
    adapter.register("GET", "/$API_V2_CURRENT_SEMESTER_URL", current);
    final dio = Dio(BaseOptions(baseUrl: "http://test/"))
      ..httpClientAdapter = adapter;
    repository = SemesterRepository(dio);
  });

  test("parses the v2 semester list and preserves semester code", () async {
    final semesters = await repository.fetchSemesters();

    expect(semesters, hasLength(1));
    expect(semesters.single.year, 2026);
    expect(semesters.single.semester, 3);
    expect(semesters.single.courseRegistrationPeriodStart, isNull);
  });

  test("parses the v2 current semester and nullable periods", () async {
    final semester = await repository.fetchCurrent();

    expect(semester.semester, 3);
    expect(semester.courseDesciptionSubmission, isNotNull);
    expect(semester.courseRegistrationPeriodStart, isNull);
    expect(semester.courseRegistrationPeriodEnd, isNotNull);
    expect(semester.gradePosting, isNotNull);
  });

  test("fails at the parsing boundary when a core field is missing", () {
    expect(
      () => Semester.fromV2Json(<String, dynamic>{
        "year": 2026,
        "semester": 3,
        "beginning": "2026-09-01T00:00:00.000Z",
      }),
      throwsA(anything),
    );
  });
}
