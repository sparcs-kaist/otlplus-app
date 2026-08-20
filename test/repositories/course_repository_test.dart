import "dart:convert";
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/course.dart";
import "package:otlplus/repositories/course_repository.dart";

import "../utils/fake_http.dart";

void main() {
  late FakeHttpAdapter adapter;
  late CourseRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: "http://test/"))
      ..httpClientAdapter = adapter;
    repository = CourseRepository(dio);
  });

  test("search parses the v2 envelope with compatibility defaults", () async {
    final fixture =
        jsonDecode(
              await File("test/fixtures/v2/courses_search.json").readAsString(),
            )
            as Map<String, dynamic>;
    adapter.register("GET", "/$API_V2_COURSES_URL?limit=100&offset=0", fixture);

    final result = await repository.search(const CourseSearchQuery());

    expect(result.totalCount, 1);
    expect(result.courses, hasLength(1));
    final course = result.courses.single;
    expect(course.id, 24732);
    expect(course.oldCode, "AX.20002");
    expect(course.title, "AI모델 및 알고리즘의 이해");
    expect(course.titleEn, course.title);
    expect(course.type, "전공필수");
    expect(course.typeEn, course.type);
    expect(course.department?.name, "AX학과");
    expect(course.department?.nameEn, "AX학과");
    expect(course.professors.single.nameEn, "문일철");
    expect(course.reviewTotalWeight, 0);
    expect(course.grade, 0);
    expect(course.load, 0);
    expect(course.speech, 0);
    expect(course.credit, 0);
    expect(course.creditAU, 0);
    expect(course.open, isFalse);
    expect(course.completed, isFalse);
  });

  test("search maps list filters to repeated v2 query values", () async {
    adapter.register(
      "GET",
      "/$API_V2_COURSES_URL"
          "?department=623&department=9945&keyword=ai&level=100&level=200"
          "&limit=100&offset=0&order=popular&term=3&type=BR&type=MR",
      <String, dynamic>{"courses": <dynamic>[], "totalCount": 0},
    );

    final result = await repository.search(
      const CourseSearchQuery(
        keyword: "ai",
        types: <String>["BR", "MR"],
        departments: <int>[623, 9945],
        levels: <int>[100, 200],
        term: 3,
        order: "popular",
      ),
    );

    expect(result.courses, isEmpty);
    expect(result.totalCount, 0);
  });

  test("search fetches 100 per page and stops at totalCount", () async {
    adapter.register(
      "GET",
      "/$API_V2_COURSES_URL?limit=100&offset=0",
      <String, dynamic>{
        "courses": List<Map<String, dynamic>>.generate(
          100,
          (index) => _searchCourse(index + 1),
        ),
        "totalCount": 250,
      },
    );
    adapter.register(
      "GET",
      "/$API_V2_COURSES_URL?limit=100&offset=100",
      <String, dynamic>{
        "courses": List<Map<String, dynamic>>.generate(
          100,
          (index) => _searchCourse(index + 101),
        ),
        "totalCount": 250,
      },
    );
    adapter.register(
      "GET",
      "/$API_V2_COURSES_URL?limit=100&offset=200",
      <String, dynamic>{
        "courses": List<Map<String, dynamic>>.generate(
          50,
          (index) => _searchCourse(index + 201),
        ),
        "totalCount": 250,
      },
    );

    final result = await repository.search(const CourseSearchQuery());

    expect(result.totalCount, 250);
    expect(result.courses, hasLength(250));
    expect(result.courses.first.id, 1);
    expect(result.courses.last.id, 250);
  });

  test("search caps pagination at 300 courses", () async {
    for (var offset = 0; offset < 300; offset += 100) {
      adapter.register(
        "GET",
        "/$API_V2_COURSES_URL?limit=100&offset=$offset",
        <String, dynamic>{
          "courses": List<Map<String, dynamic>>.generate(
            100,
            (index) => _searchCourse(index + offset + 1),
          ),
          "totalCount": 350,
        },
      );
    }

    final result = await repository.search(const CourseSearchQuery());

    expect(result.totalCount, 350);
    expect(result.courses, hasLength(300));
    expect(result.courses.last.id, 300);
  });

  test("detail parses v2 fields and nested history safely", () async {
    final fixture =
        jsonDecode(
              await File("test/fixtures/v2/course_detail.json").readAsString(),
            )
            as Map<String, dynamic>;
    adapter.register(
      "GET",
      "/${API_V2_COURSE_DETAIL_URL.replaceFirst("{id}", "24732")}",
      fixture,
    );

    final course = await repository.fetchDetail(24732);

    expect(course.oldCode, "AX.20002");
    expect(course.titleEn, course.title);
    expect(course.classDuration, 3);
    expect(course.expDuration, 0);
    expect(course.credit, 3);
    expect(course.creditAU, 0);
    expect(course.history, hasLength(1));
    final history = course.history.single;
    expect(history.year, 2026);
    expect(history.semester, 3);
    expect(history.myLectureId, isNull);
    expect(history.classes, hasLength(1));
    final courseClass = history.classes.single;
    expect(courseClass.lectureId, 1929802);
    expect(courseClass.classNo, "");
    expect(courseClass.subtitle, "");
    expect(courseClass.professors.single.professorId, 229);
    expect(course.professors.single.professorId, 229);
  });

  test(
    "detail tolerates absent optional department and history fields",
    () async {
      adapter.register(
        "GET",
        "/${API_V2_COURSE_DETAIL_URL.replaceFirst("{id}", "1")}",
        <String, dynamic>{
          "id": 1,
          "name": "과목",
          "code": "TEST.100",
          "type": "기타",
        },
      );

      final course = await repository.fetchDetail(1);

      expect(course.department, isNull);
      expect(course.professors, isEmpty);
      expect(course.history, isEmpty);
      expect(course.summary, "");
      expect(course.classDuration, 0);
      expect(course.expDuration, 0);
      expect(course.credit, 0);
      expect(course.creditAU, 0);
    },
  );

  test("required v2 course fields reject missing or wrong types", () {
    final valid = _searchCourse(1);

    expect(
      () => Course.fromV2Json(Map<String, dynamic>.from(valid)..remove("id")),
      throwsFormatException,
    );
    expect(
      () => Course.fromV2Json(<String, dynamic>{...valid, "name": 123}),
      throwsFormatException,
    );
    expect(
      () => Course.fromV2Json(<String, dynamic>{...valid, "code": false}),
      throwsFormatException,
    );
    expect(
      () => Course.fromV2Json(Map<String, dynamic>.from(valid)..remove("type")),
      throwsFormatException,
    );
    expect(
      () => Course.fromV2Json(<String, dynamic>{...valid, "id": 0}),
      throwsFormatException,
    );
    expect(
      () => Course.fromV2Json(<String, dynamic>{...valid, "name": " "}),
      throwsFormatException,
    );
  });

  test("required v2 history identifiers reject malformed values", () {
    final valid = _searchCourse(1);

    expect(
      () => Course.fromV2Json(<String, dynamic>{
        ...valid,
        "history": <dynamic>[
          <String, dynamic>{"semester": 3, "classes": <dynamic>[]},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => Course.fromV2Json(<String, dynamic>{
        ...valid,
        "history": <dynamic>[
          <String, dynamic>{
            "year": 2026,
            "semester": 3,
            "classes": <dynamic>[
              <String, dynamic>{"lectureId": "1929802"},
            ],
          },
        ],
      }),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _searchCourse(int id) {
  return <String, dynamic>{
    "id": id,
    "name": "Course $id",
    "code": "TEST.$id",
    "type": "Type",
    "department": <String, dynamic>{"id": 1, "name": "Department"},
    "professors": <dynamic>[],
    "summary": "",
    "open": true,
    "completed": false,
  };
}
