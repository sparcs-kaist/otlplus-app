import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/widgets/timetable.dart";

Future<Map<String, dynamic>> _readFixture(String path) async {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: "Missing fixture: $path");
  return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
}

List<Map<String, dynamic>> _timetableLectures(Map<String, dynamic> fixture) {
  return (fixture["lectures"] as List<dynamic>)
      .map((lecture) => lecture as Map<String, dynamic>)
      .toList(growable: false);
}

List<Map<String, dynamic>> _searchLectures(Map<String, dynamic> fixture) {
  return (fixture["courses"] as List<dynamic>)
      .expand(
        (course) =>
            ((course as Map<String, dynamic>)["lectures"] as List<dynamic>),
      )
      .map((lecture) => lecture as Map<String, dynamic>)
      .toList(growable: false);
}

void _expectDayRoundTrip(Map<String, dynamic> rawLecture, Lecture lecture) {
  final rawClasses = rawLecture["classes"] as List<dynamic>;
  final rawExamTimes = rawLecture["examTimes"] as List<dynamic>;
  final serializedLecture = lecture.toJson();
  final serializedClasses = serializedLecture["classtimes"] as List<dynamic>;
  final serializedExamTimes = serializedLecture["examtimes"] as List<dynamic>;

  expect(lecture.classtimes, hasLength(rawClasses.length));
  expect(serializedClasses, hasLength(rawClasses.length));
  for (var index = 0; index < rawClasses.length; index++) {
    final rawDay = (rawClasses[index] as Map<String, dynamic>)["day"] as int;
    // Wire format only: the parsed field's internal type may change; the
    // emitted JSON day must stay the raw integer.
    expect(lecture.classtimes[index].toJson()["day"], rawDay);
    expect((serializedClasses[index] as Map<String, dynamic>)["day"], rawDay);
  }

  expect(lecture.examtimes, hasLength(rawExamTimes.length));
  expect(serializedExamTimes, hasLength(rawExamTimes.length));
  for (var index = 0; index < rawExamTimes.length; index++) {
    final rawDay = (rawExamTimes[index] as Map<String, dynamic>)["day"] as int;
    expect(lecture.examtimes[index].toJson()["day"], rawDay);
    expect((serializedExamTimes[index] as Map<String, dynamic>)["day"], rawDay);
  }
}

void main() {
  group("weekday integer characterization", () {
    test(
      "v2 timetable fixture preserves and re-emits every day integer",
      () async {
        final fixture = await _readFixture(
          "test/fixtures/v2/timetable_detail.json",
        );

        for (final rawLecture in _timetableLectures(fixture)) {
          final lecture = Lecture.fromV2Json(
            rawLecture,
            year: 2026,
            semester: 3,
          );
          _expectDayRoundTrip(rawLecture, lecture);
        }
      },
    );

    test(
      "v2 lecture search fixture preserves and re-emits every day integer",
      () async {
        final fixture = await _readFixture(
          "test/fixtures/v2/lectures_search.json",
        );

        for (final rawLecture in _searchLectures(fixture)) {
          final lecture = Lecture.fromV2Json(
            rawLecture,
            year: 2026,
            semester: 1,
          );
          _expectDayRoundTrip(rawLecture, lecture);
        }
      },
    );

    test(
      "timetable weekday labels keep the current Monday-first wire order",
      () {
        expect(DAYSOFWEEK, <String>[
          "mon",
          "tue",
          "wed",
          "thu",
          "fri",
          "sat",
          "sun",
        ]);
      },
    );

    test("DateTime weekdays 1 through 7 map to app days 0 through 6", () {
      final cases = <({DateTime date, int weekday, int appDay})>[
        (date: DateTime(2024, 1, 1), weekday: 1, appDay: 0),
        (date: DateTime(2024, 1, 2), weekday: 2, appDay: 1),
        (date: DateTime(2024, 1, 3), weekday: 3, appDay: 2),
        (date: DateTime(2024, 1, 4), weekday: 4, appDay: 3),
        (date: DateTime(2024, 1, 5), weekday: 5, appDay: 4),
        (date: DateTime(2024, 1, 6), weekday: 6, appDay: 5),
        (date: DateTime(2024, 1, 7), weekday: 7, appDay: 6),
      ];

      for (final testCase in cases) {
        expect(testCase.date.weekday, testCase.weekday);
        expect(testCase.date.weekday - 1, testCase.appDay);
      }
    });
  });
}
