import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/repositories/info_repository.dart";

import "../utils/fake_http.dart";

void main() {
  late FakeHttpAdapter adapter;
  late InfoRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    adapter.register("GET", "/$API_SEMESTER_URL", <Map<String, dynamic>>[
      <String, dynamic>{
        "year": 2026,
        "semester": 3,
        "beginning": "2026-09-01T00:00:00.000Z",
        "end": "2026-12-31T00:00:00.000Z",
        "courseDesciptionSubmission": null,
        "courseRegistrationPeriodStart": null,
        "courseRegistrationPeriodEnd": null,
        "courseAddDropPeriodEnd": null,
        "courseDropDeadline": null,
        "courseEvaluationDeadline": null,
        "gradePosting": null,
      },
    ]);
    adapter.register("GET", "/$SESSION_INFO_URL", <String, dynamic>{
      "id": 42,
      "email": "test@example.com",
      "student_id": "20260001",
      "firstName": "Test",
      "lastName": "User",
      "majors": <dynamic>[],
      "departments": <dynamic>[],
      "favorite_departments": <dynamic>[],
      "review_writable_lectures": <dynamic>[],
      "my_timetable_lectures": <dynamic>[],
      "reviews": <dynamic>[],
    });
    final dio = Dio(BaseOptions(baseUrl: "http://test/"))
      ..httpClientAdapter = adapter;
    repository = InfoRepository(dio);
  });

  test("fetchSemesters parses the legacy semester list", () async {
    final semesters = await repository.fetchSemesters();

    expect(semesters, hasLength(1));
    expect(semesters.single.year, 2026);
    expect(semesters.single.semester, 3);
    expect(semesters.single.courseRegistrationPeriodStart, isNull);
  });

  test("fetchSessionInfo parses the legacy session user", () async {
    final user = await repository.fetchSessionInfo();

    expect(user.id, 42);
    expect(user.email, "test@example.com");
    expect(user.studentId, "20260001");
    expect(user.firstName, "Test");
    expect(user.lastName, "User");
  });
}
