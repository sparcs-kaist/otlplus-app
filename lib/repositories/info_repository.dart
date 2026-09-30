import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/semester.dart";
import "package:otlplus/models/user.dart";
import "package:otlplus/repositories/semester_repository.dart";

class InfoRepository {
  InfoRepository(this._dio);

  final Dio _dio;

  Future<List<Semester>> fetchSemesters() =>
      SemesterRepository(_dio).fetchSemesters();

  Future<User> fetchSessionInfo() async {
    final response = await _dio.get(SESSION_INFO_URL);
    return User.fromJson(response.data);
  }
}
