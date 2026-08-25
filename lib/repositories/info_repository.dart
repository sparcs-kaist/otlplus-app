import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/semester.dart";
import "package:otlplus/models/user.dart";

class InfoRepository {
  InfoRepository(this._dio);

  final Dio _dio;

  Future<List<Semester>> fetchSemesters() async {
    final response = await _dio.get(API_SEMESTER_URL);
    final rawSemesters = response.data as List;
    return rawSemesters.map((semester) => Semester.fromJson(semester)).toList();
  }

  Future<User> fetchSessionInfo() async {
    final response = await _dio.get(SESSION_INFO_URL);
    return User.fromJson(response.data);
  }
}
