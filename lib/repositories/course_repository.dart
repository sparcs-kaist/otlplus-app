import "dart:math";

import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/course.dart";

class CourseSearchQuery {
  const CourseSearchQuery({
    this.keyword = "",
    this.types = const <String>[],
    this.departments = const <int>[],
    this.levels = const <int>[],
    this.term,
    this.order,
  });

  final String keyword;
  final List<String> types;
  final List<int> departments;
  final List<int> levels;
  final int? term;
  final String? order;

  Map<String, Object> toQueryParameters() {
    return <String, Object>{
      if (keyword.isNotEmpty) "keyword": keyword,
      if (types.isNotEmpty) "type": types,
      if (departments.isNotEmpty) "department": departments,
      if (levels.isNotEmpty) "level": levels,
      if (term != null) "term": term!,
      if (order != null) "order": order!,
    };
  }
}

class CourseSearchResult {
  const CourseSearchResult({required this.courses, required this.totalCount});

  final List<Course> courses;
  final int totalCount;
}

class CourseRepository {
  CourseRepository(this._dio);

  static const int pageSize = 100;
  static const int maxCourseCount = 300;

  final Dio _dio;

  Future<CourseSearchResult> search(CourseSearchQuery query) async {
    final courses = <Course>[];
    var totalCount = 0;
    var offset = 0;

    while (courses.length < maxCourseCount) {
      final response = await _dio.get<Map<String, dynamic>>(
        API_V2_COURSES_URL,
        queryParameters: <String, Object>{
          ...query.toQueryParameters(),
          "offset": offset,
          "limit": pageSize,
        },
        options: Options(listFormat: ListFormat.multi),
      );
      final data = response.data ?? const <String, dynamic>{};
      final rawCourses = _jsonList(data["courses"]);
      final responseTotalCount = data["totalCount"];

      if (responseTotalCount is num) {
        totalCount = responseTotalCount.toInt();
      } else if (offset == 0) {
        totalCount = rawCourses.length;
      }

      final targetCount = min(totalCount, maxCourseCount);
      final remaining = targetCount - courses.length;
      if (remaining > 0) {
        courses.addAll(rawCourses.take(remaining).map(Course.fromV2Json));
      }

      if (courses.length >= targetCount || rawCourses.isEmpty) break;
      offset += pageSize;
    }

    return CourseSearchResult(
      courses: List<Course>.unmodifiable(courses),
      totalCount: totalCount,
    );
  }

  Future<Course> fetchDetail(int courseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      API_V2_COURSE_DETAIL_URL.replaceFirst("{id}", courseId.toString()),
    );
    return Course.fromV2Json(response.data ?? const <String, dynamic>{});
  }
}

List<Map<String, dynamic>> _jsonList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
}
