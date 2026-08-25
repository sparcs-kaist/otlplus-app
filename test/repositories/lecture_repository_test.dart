import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/models/time.dart";
import "package:otlplus/repositories/lecture_repository.dart";

import "../utils/fake_http.dart";
import "../utils/samples.dart";

class CapturingHttpAdapter extends FakeHttpAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return super.fetch(options, requestStream, cancelFuture);
  }
}

Map<String, dynamic> _lectureFromFixture(Map<String, dynamic> fixture) {
  final courses = fixture["courses"] as List<dynamic>;
  final course = courses.single as Map<String, dynamic>;
  final lectures = course["lectures"] as List<dynamic>;
  return Map<String, dynamic>.from(lectures.single as Map<String, dynamic>);
}

void main() {
  late Map<String, dynamic> searchFixture;

  setUpAll(() async {
    searchFixture =
        jsonDecode(
              await File(
                "test/fixtures/v2/lectures_search.json",
              ).readAsString(),
            )
            as Map<String, dynamic>;
  });

  test(
    "maps v2 filters as repeated parameters and parses localized lectures",
    () async {
      final adapter = CapturingHttpAdapter();
      final expectedUri = Uri(
        path: "/$API_V2_LECTURES_URL",
        queryParameters: <String, dynamic>{
          "year": "2026",
          "semester": "1",
          "keyword": "알고리즘",
          "type": <String>["BR", "ME"],
          "department": <String>["623", "9945"],
          "level": <String>["300", "600"],
          "day": "0",
          "begin": "540",
          "end": "1080",
          "order": "code",
          "limit": "100",
          "offset": "0",
        },
      );
      adapter.register("GET", expectedUri.toString(), searchFixture);
      final repository = LectureRepository(
        Dio(BaseOptions(baseUrl: "http://test/"))..httpClientAdapter = adapter,
      );

      final lectures = await repository.search(
        const LectureSearchQuery(
          year: 2026,
          semester: 1,
          keyword: "알고리즘",
          types: <String>["BR", "ME"],
          departments: <int>[623, 9945],
          levels: <int>[300, 600],
          day: 0,
          begin: 540,
          end: 1080,
          order: "code",
        ),
      );

      expect(adapter.requests, hasLength(1));
      final query = adapter.requests.single.uri.queryParametersAll;
      expect(query["year"], <String>["2026"]);
      expect(query["semester"], <String>["1"]);
      expect(query["type"], <String>["BR", "ME"]);
      expect(query["department"], <String>["623", "9945"]);
      expect(query["level"], <String>["300", "600"]);
      expect(query["limit"], <String>["100"]);
      expect(query["offset"], <String>["0"]);

      expect(lectures, hasLength(1));
      final lecture = lectures.single;
      expect(lecture.id, 1921750);
      expect(lecture.course, 23742);
      expect(lecture.year, 2026);
      expect(lecture.semester, 1);
      expect(lecture.title, "알고리즘 거래와 고빈도 금융");
      expect(lecture.titleEn, lecture.title);
      expect(lecture.commonTitle, lecture.title);
      expect(lecture.classTitle, "");
      expect(lecture.oldCode, "BAF.60073");
      expect(lecture.department, 17186);
      expect(lecture.departmentName, "디지털금융MBA");
      expect(lecture.departmentNameEn, lecture.departmentName);
      expect(lecture.type, "선택(석/박사)");
      expect(lecture.limit, 50);
      expect(lecture.numPeople, 1);
      expect(lecture.credit, 3);
      expect(lecture.creditAu, 0);
      expect(lecture.grade, 0);
      expect(lecture.load, 0);
      expect(lecture.speech, 0);
      expect(lecture.isEnglish, isFalse);
      expect(lecture.classDuration, 3);
      expect(lecture.expDuration, 0);

      expect(lecture.professors, hasLength(1));
      expect(lecture.professors.single.professorId, 4184);
      expect(lecture.professors.single.name, "황근호");
      expect(lecture.professors.single.nameEn, "황근호");

      expect(lecture.classtimes, hasLength(1));
      final classtime = lecture.classtimes.single;
      expect(classtime.day, Weekday.fromCode(4));
      expect(classtime.begin, 1140);
      expect(classtime.end, 1320);
      expect(classtime.buildingCode, "Z02");
      expect(classtime.classroom, "(Z02)여의도캠퍼스(기타)");
      expect(classtime.classroomShort, "Z02");
      expect(classtime.roomName, "(1712호)강의실");

      expect(lecture.examtimes, hasLength(1));
      final examtime = lecture.examtimes.single;
      expect(examtime.day, Weekday.fromCode(2));
      expect(examtime.str, "13:00~15:00");
      expect(examtime.strEn, examtime.str);
      expect(examtime.begin, 780);
      expect(examtime.end, 900);
    },
  );

  test("keeps v2 Monday as weekday zero", () {
    final lectureJson = _lectureFromFixture(searchFixture);
    lectureJson["classes"] = <Map<String, dynamic>>[
      <String, dynamic>{
        "day": 0,
        "begin": 540,
        "end": 600,
        "buildingCode": "E3",
        "buildingName": "정보전자공학동",
        "roomName": "101호",
      },
    ];

    final lecture = Lecture.fromV2Json(lectureJson, year: 2026, semester: 1);

    expect(lecture.classtimes.single.day, Weekday.monday);
  });

  test("keeps v2 subtitle separate from the observable lecture title", () {
    final lectureJson = _lectureFromFixture(searchFixture)
      ..["name"] = "SF영화: 외계세계탐험"
      ..["subtitle"] = "A";

    final lecture = Lecture.fromV2Json(lectureJson, year: 2026, semester: 1);

    expect(lecture.title, "SF영화: 외계세계탐험");
    expect(lecture.titleEn, "SF영화: 외계세계탐험");
    expect(lecture.commonTitle, "SF영화: 외계세계탐험");
    expect(lecture.commonTitleEn, "SF영화: 외계세계탐험");
    expect(lecture.classTitle, "A");
    expect(lecture.classTitleEn, "A");
  });

  test("fetches at most three pages of 100 lectures", () async {
    final adapter = CapturingHttpAdapter();
    final baseLecture = _lectureFromFixture(searchFixture);

    for (final offset in <int>[0, 100, 200]) {
      final courses = List<Map<String, dynamic>>.generate(100, (index) {
        final id = offset + index + 1;
        return <String, dynamic>{
          "id": id,
          "name": "Course $id",
          "code": "CS.$id",
          "type": "전공선택",
          "lectures": <Map<String, dynamic>>[
            <String, dynamic>{
              ...baseLecture,
              "id": id,
              "courseId": id,
              "name": "Course $id",
              "code": "CS.$id",
            },
          ],
          "completed": false,
        };
      });
      final uri = Uri(
        path: "/$API_V2_LECTURES_URL",
        queryParameters: <String, dynamic>{
          "year": "2026",
          "semester": "1",
          "limit": "100",
          "offset": offset.toString(),
        },
      );
      adapter.register("GET", uri.toString(), <String, dynamic>{
        "courses": courses,
      });
    }
    final repository = LectureRepository(
      Dio(BaseOptions(baseUrl: "http://test/"))..httpClientAdapter = adapter,
    );

    final lectures = await repository.search(
      const LectureSearchQuery(year: 2026, semester: 1),
    );

    expect(lectures, hasLength(300));
    expect(adapter.requests, hasLength(3));
    expect(
      adapter.requests
          .map((request) => request.uri.queryParameters["offset"])
          .toList(),
      <String>["0", "100", "200"],
    );
  });

  test("keeps v1 lecture detail and related review calls explicit", () async {
    final adapter = CapturingHttpAdapter();
    final reviewJson = SampleReview.shared.toJson();
    (reviewJson["course"] as Map<String, dynamic>)["department"] =
        SampleDepartment.shared.toJson();
    adapter.register(
      "GET",
      "/$API_LECTURE_URL/${SampleLecture.id}",
      SampleLecture.shared.toJson(),
    );
    adapter.register(
      "GET",
      "/${API_LECTURE_RELATED_REVIEWS_URL.replaceFirst("{id}", SampleLecture.id.toString())}",
      <Map<String, dynamic>>[reviewJson],
    );
    final repository = LectureRepository(
      Dio(BaseOptions(baseUrl: "http://test/"))..httpClientAdapter = adapter,
    );

    final lecture = await repository.fetchLegacyDetail(SampleLecture.id);
    final reviews = await repository.fetchLegacyRelatedReviews(
      SampleLecture.id,
    );

    expect(lecture, SampleLecture.shared);
    expect(reviews, <Object>[SampleReview.shared]);
    expect(adapter.requests.map((request) => request.uri.path).toList(), <
      String
    >[
      "/$API_LECTURE_URL/${SampleLecture.id}",
      "/${API_LECTURE_RELATED_REVIEWS_URL.replaceFirst("{id}", SampleLecture.id.toString())}",
    ]);
  });

  test("fetches retained v1 course lectures through the named route", () async {
    final adapter = CapturingHttpAdapter();
    final path = API_COURSE_LECTURES_URL.replaceFirst(
      "{id}",
      SampleCourse.id.toString(),
    );
    adapter.register("GET", "/$path", <Map<String, dynamic>>[
      SampleLecture.shared.toJson(),
    ]);
    final repository = LectureRepository(
      Dio(BaseOptions(baseUrl: "http://test/"))..httpClientAdapter = adapter,
    );

    final lectures = await repository.fetchLegacyCourseLectures(
      SampleCourse.id,
    );

    expect(lectures, <Lecture>[SampleLecture.shared]);
    expect(adapter.requests.single.uri.path, "/$path");
  });
}
