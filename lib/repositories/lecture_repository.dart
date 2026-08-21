import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/models/review.dart";

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

  /// Fetches a lecture detail from the retained v1 `api/lectures/{id}` API.
  Future<Lecture> fetchLegacyDetail(int lectureId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      "$API_LECTURE_URL/$lectureId",
    );
    return Lecture.fromJson(response.data ?? const <String, dynamic>{});
  }

  /// Fetches course lectures from the retained v1 course lectures API.
  Future<List<Lecture>> fetchLegacyCourseLectures(int courseId) async {
    final response = await _dio.get<List<dynamic>>(
      API_COURSE_LECTURES_URL.replaceFirst("{id}", courseId.toString()),
    );
    return List<Lecture>.unmodifiable(
      (response.data ?? const <dynamic>[]).whereType<Map>().map(
        (lecture) => Lecture.fromJson(Map<String, dynamic>.from(lecture)),
      ),
    );
  }

  /// Fetches reviews from the retained v1 lecture related-reviews API.
  Future<List<Review>> fetchLegacyRelatedReviews(int lectureId) async {
    final response = await _dio.get<List<dynamic>>(
      API_LECTURE_RELATED_REVIEWS_URL.replaceFirst(
        "{id}",
        lectureId.toString(),
      ),
    );
    return List<Review>.unmodifiable(
      (response.data ?? const <dynamic>[]).whereType<Map>().map(
        (review) => Review.fromJson(Map<String, dynamic>.from(review)),
      ),
    );
  }
}

List<Map<String, dynamic>> _jsonList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
}
