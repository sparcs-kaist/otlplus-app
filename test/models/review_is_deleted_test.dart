import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:otlplus/models/review.dart";

Future<Map<String, dynamic>> _readFixture(String path) async {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: "Missing fixture: $path");
  return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
}

Map<String, dynamic> _v2ReviewPayload(bool isDeleted) {
  return <String, dynamic>{
    "id": 1,
    "courseId": 24732,
    "courseName": "AI모델 및 알고리즘의 이해",
    "lectureId": 1929802,
    "professors": <Map<String, dynamic>>[
      <String, dynamic>{"id": 229, "name": "문일철"},
    ],
    "year": 2026,
    "semester": 3,
    "content": "inline v2 review",
    "like": 0,
    "grade": 4,
    "load": 3,
    "speech": 4,
    "isDeleted": isDeleted,
    "likedByUser": false,
  };
}

Map<String, dynamic> _v1ReviewPayload(int isDeleted) {
  return <String, dynamic>{
    "id": 1,
    "course": <String, dynamic>{
      "id": 24732,
      "old_code": "CS000",
      "department": <String, dynamic>{
        "id": 1,
        "name": "전산학부",
        "name_en": "School of Computing",
        "code": "CS",
      },
      "type": "전공",
      "type_en": "Major",
      "title": "AI모델 및 알고리즘의 이해",
      "title_en": "Understanding AI Models and Algorithms",
      "summary": "",
      "review_total_weight": 0.0,
    },
    "lecture": <String, dynamic>{
      "id": 1929802,
      "title": "AI모델 및 알고리즘의 이해",
      "title_en": "Understanding AI Models and Algorithms",
      "course": 24732,
      "old_code": "CS000",
      "class_no": "A",
      "year": 2026,
      "semester": 3,
      "code": "CS000",
      "department": 1,
      "department_code": "CS",
      "department_name": "전산학부",
      "department_name_en": "School of Computing",
      "type": "전공",
      "type_en": "Major",
      "limit": 100,
      "num_people": 50,
      "is_english": false,
      "credit": 3,
      "credit_au": 0,
      "common_title": "AI모델 및 알고리즘의 이해",
      "common_title_en": "Understanding AI Models and Algorithms",
      "class_title": "",
      "class_title_en": "",
      "review_total_weight": 0.0,
      "professors": <Map<String, dynamic>>[
        <String, dynamic>{
          "name": "문일철",
          "name_en": "Moon Il-Chul",
          "professor_id": 229,
          "review_total_weight": 0.0,
        },
      ],
    },
    "content": "inline v1 review",
    "like": 0,
    "is_deleted": isDeleted,
    "grade": 4,
    "load": 3,
    "speech": 4,
    "userspecific_is_liked": false,
  };
}

void _expectLegacyDeletionSerialization(Review review, int expected) {
  final serialized = review.toJson();

  // Wire format only: the internal field type may change; the emitted
  // legacy key must stay the integer.
  expect(serialized["is_deleted"], expected);
  expect(serialized.containsKey("isDeleted"), isFalse);
  expect(serialized.keys, contains("is_deleted"));
}

void main() {
  group("Review.isDeleted characterization", () {
    for (final fixturePath in <String>[
      "test/fixtures/v2/reviews_liked.json",
      "test/fixtures/v2/reviews_recent.json",
      "test/fixtures/v2/reviews_course_default.json",
    ]) {
      test("$fixturePath keeps false as legacy integer zero", () async {
        final fixture = await _readFixture(fixturePath);
        final rawReview = (fixture["reviews"] as List<dynamic>).single;
        final review = Review.fromV2Json(rawReview as Map<String, dynamic>);

        _expectLegacyDeletionSerialization(review, 0);
      });
    }

    test("v2 isDeleted false becomes zero and serializes as is_deleted", () {
      final review = Review.fromV2Json(_v2ReviewPayload(false));

      _expectLegacyDeletionSerialization(review, 0);
    });

    test("v2 isDeleted true becomes one and serializes as is_deleted", () {
      final review = Review.fromV2Json(_v2ReviewPayload(true));

      _expectLegacyDeletionSerialization(review, 1);
    });

    test("v1 is_deleted zero stays zero and keeps the legacy shape", () {
      final review = Review.fromJson(_v1ReviewPayload(0));

      _expectLegacyDeletionSerialization(review, 0);
    });

    test("v1 is_deleted one stays one and keeps the legacy shape", () {
      final review = Review.fromJson(_v1ReviewPayload(1));

      _expectLegacyDeletionSerialization(review, 1);
    });
  });
}
