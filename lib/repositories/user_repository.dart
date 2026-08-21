import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/user.dart";

class UserRepository {
  UserRepository(this._dio);

  final Dio _dio;

  Future<User?> fetchInfo() async {
    final response = await _dio.get<Map<String, dynamic>?>(
      API_V2_USER_INFO_URL,
    );
    final data = response.data;
    if (data == null) return null;
    return User.fromV2Json(data);
  }
}
