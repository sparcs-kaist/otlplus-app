import "dart:convert";
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/user.dart";
import "package:otlplus/repositories/user_repository.dart";

import "../utils/fake_http.dart";

void main() {
  late Map<String, dynamic> fixture;

  setUp(() async {
    fixture =
        jsonDecode(await File("test/fixtures/v2/user_info.json").readAsString())
            as Map<String, dynamic>;
  });

  group("User.fromV2Json", () {
    test("maps profile fields and compatibility collections strictly", () {
      final user = User.fromV2Json(fixture);

      expect(user.id, 42);
      expect(user.email, "hong@kaist.ac.kr");
      expect(user.studentId, "20261234");
      expect(user.firstName, "홍길동");
      expect(user.lastName, isEmpty);
      expect(user.displayName, "홍길동");
      expect(user.degree, "학사");

      expect(user.majors, hasLength(2));
      expect(user.departments, hasLength(2));
      expect(user.majors, isNot(same(user.departments)));
      expect(user.majors.first.id, 24356);
      expect(user.majors.first.name, "전산학부");
      expect(user.majors.first.nameEn, "전산학부");
      expect(user.majors.first.code, isEmpty);

      expect(user.favoriteDepartments, hasLength(1));
      expect(user.favoriteDepartments!.single.id, 623);
      expect(user.favoriteDepartments!.single.name, "물리학과");
      expect(user.favoriteDepartments!.single.nameEn, "물리학과");
      expect(user.favoriteDepartments!.single.code, isEmpty);

      expect(user.myTimetableLectures, isEmpty);
      expect(user.reviewWritableLectures, isEmpty);
      expect(user.reviews, isEmpty);
    });

    for (final invalidField in <String, Object>{
      "id": 0,
      "name": " ",
      "mail": "",
      "studentNumber": 0,
    }.entries) {
      test("rejects invalid ${invalidField.key}", () {
        expect(
          () => User.fromV2Json(<String, dynamic>{
            ...fixture,
            invalidField.key: invalidField.value,
          }),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test("accepts a nullable degree without weakening core field types", () {
      final user = User.fromV2Json(<String, dynamic>{
        ...fixture,
        "degree": null,
      });

      expect(user.degree, isNull);
      expect(
        () => User.fromV2Json(<String, dynamic>{
          ...fixture,
          "studentNumber": "20261234",
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group("User legacy JSON", () {
    test("preserves v1 keys and values", () {
      final legacyJson = <String, dynamic>{
        "id": 7,
        "email": "legacy@kaist.ac.kr",
        "student_id": "20200001",
        "firstName": "Legacy",
        "lastName": "User",
        "majors": <Map<String, dynamic>>[],
        "departments": <Map<String, dynamic>>[],
        "favorite_departments": <Map<String, dynamic>>[],
        "review_writable_lectures": <Map<String, dynamic>>[],
        "my_timetable_lectures": <Map<String, dynamic>>[],
        "reviews": <Map<String, dynamic>>[],
      };

      final user = User.fromJson(legacyJson);

      expect(user.displayName, "Legacy User");
      expect(user.degree, isNull);
      expect(user.toJson(), legacyJson);
    });
  });

  group("UserRepository.fetchInfo", () {
    test("fetches and parses v2 user info", () async {
      final adapter = FakeHttpAdapter()
        ..register("GET", "/$API_V2_USER_INFO_URL", fixture);
      final dio = Dio(BaseOptions(baseUrl: "http://test/"))
        ..httpClientAdapter = adapter;

      final user = await UserRepository(dio).fetchInfo();

      expect(user, isNotNull);
      expect(user!.id, 42);
      expect(user.displayName, "홍길동");
    });

    test("returns null when the server response is null", () async {
      final adapter = FakeHttpAdapter()
        ..register("GET", "/$API_V2_USER_INFO_URL", null);
      final dio = Dio(BaseOptions(baseUrl: "http://test/"))
        ..httpClientAdapter = adapter;

      final user = await UserRepository(dio).fetchInfo();

      expect(user, isNull);
    });
  });
}
