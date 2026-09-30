import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/lecture.dart";

class LectureSearchQuery {
  const LectureSearchQuery({
    required this.year,
    required this.semester,
    this.keyword = "",
    this.types = const <String>[],
    this.departments = const <int>[],
    this.levels = const <int>[],
    this.day,
    this.begin,
    this.end,
    this.order,
  });

  final int year;
  final int semester;
  final String keyword;
  final List<String> types;
  final List<int> departments;
  final List<int> levels;
  final int? day;
  final int? begin;
  final int? end;
  final String? order;

  Map<String, Object> toQueryParameters() {
    return <String, Object>{
      "year": year,
      "semester": semester,
      if (keyword.isNotEmpty) "keyword": keyword,
      if (types.isNotEmpty) "type": types,
      if (departments.isNotEmpty) "department": departments,
      if (levels.isNotEmpty) "level": levels,
      if (day != null) "day": day!,
      if (begin != null) "begin": begin!,
      if (end != null) "end": end!,
      if (order != null) "order": order!,
    };
  }
}

class LectureRepository {
  LectureRepository(this._dio);

  static const int pageSize = 100;
  static const int maxLectureCount = 300;

  final Dio _dio;

  Future<List<Lecture>> search(LectureSearchQuery query) async {
    final lectures = <Lecture>[];

    for (var offset = 0; offset < maxLectureCount; offset += pageSize) {
      final response = await _dio.get<Map<String, dynamic>>(
        API_V2_LECTURES_URL,
        queryParameters: <String, Object>{
          ...query.toQueryParameters(),
          "limit": pageSize,
          "offset": offset,
        },
        options: Options(listFormat: ListFormat.multi),
      );
      final data = response.data ?? const <String, dynamic>{};
      final pageLectures = _jsonList(data["courses"])
          .expand((course) => _jsonList(course["lectures"]))
          .map(
            (lectureJson) => Lecture.fromV2Json(
              lectureJson,
              year: query.year,
              semester: query.semester,
            ),
          )
          .toList(growable: false);

      final remaining = maxLectureCount - lectures.length;
      lectures.addAll(pageLectures.take(remaining));
      if (pageLectures.length < pageSize) break;
    }

    return List<Lecture>.unmodifiable(lectures);
  }

  /// Resolves a history entry that does not include timetable attributes.
  Future<Lecture> fetchHistoryDetail({
    required int lectureId,
    required int courseId,
    required String code,
    required int year,
    required int semester,
  }) async {
    for (var offset = 0; ; offset += pageSize) {
      final response = await _dio.get<Map<String, dynamic>>(
        API_V2_LECTURES_URL,
        queryParameters: {
          "year": year,
          "semester": semester,
          "keyword": code,
          "limit": pageSize,
          "offset": offset,
        },
      );
      final courses = _jsonList(response.data?["courses"]);
      final lectures = courses
          .expand((course) => _jsonList(course["lectures"]))
          .toList();
      for (final json in lectures) {
        if (json["id"] == lectureId && json["courseId"] == courseId) {
          return Lecture.fromV2Json(json, year: year, semester: semester);
        }
      }
      if (lectures.length < pageSize) {
        throw StateError("Lecture $lectureId was not found in v2 search");
      }
    }
  }
}

List<Map<String, dynamic>> _jsonList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
}
