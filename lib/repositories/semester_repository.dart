import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/semester.dart";

class SemesterRepository {
  SemesterRepository(this._dio);

  final Dio _dio;

  Future<List<Semester>> fetchSemesters() async {
    final response = await _dio.get<Map<String, dynamic>>(API_V2_SEMESTERS_URL);
    final data = response.data as Map<String, dynamic>;
    final semesters = data["semesters"] as List<dynamic>;

    return List<Semester>.unmodifiable(
      semesters.map(
        (semester) => Semester.fromV2Json(semester as Map<String, dynamic>),
      ),
    );
  }

  Future<Semester> fetchCurrent() async {
    final response = await _dio.get<Map<String, dynamic>>(
      API_V2_CURRENT_SEMESTER_URL,
    );
    return Semester.fromV2Json(response.data as Map<String, dynamic>);
  }
}
