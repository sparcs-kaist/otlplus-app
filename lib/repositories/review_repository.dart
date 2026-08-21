import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/review.dart";

class ReviewDepartment {
  const ReviewDepartment({required this.id, required this.name});

  final int id;
  final String name;

  factory ReviewDepartment.fromJson(Map<String, dynamic> json) {
    return ReviewDepartment(
      id: json["id"] as int,
      name: json["name"] as String,
    );
  }
}

class ReviewListResult {
  const ReviewListResult({
    required this.reviews,
    required this.averageGrade,
    required this.averageLoad,
    required this.averageSpeech,
    required this.department,
    required this.totalCount,
  });

  final List<Review> reviews;
  final double averageGrade;
  final double averageLoad;
  final double averageSpeech;
  final ReviewDepartment? department;
  final int totalCount;

  factory ReviewListResult.fromJson(Map<String, dynamic> json) {
    final department = json["department"];
    return ReviewListResult(
      reviews: List<Review>.unmodifiable(
        (json["reviews"] as List<dynamic>).map(
          (review) => Review.fromV2Json(review as Map<String, dynamic>),
        ),
      ),
      averageGrade: (json["averageGrade"] as num).toDouble(),
      averageLoad: (json["averageLoad"] as num).toDouble(),
      averageSpeech: (json["averageSpeech"] as num).toDouble(),
      department: department == null
          ? null
          : ReviewDepartment.fromJson(department as Map<String, dynamic>),
      totalCount: json["totalCount"] as int,
    );
  }
}

enum ReviewLikeAction { like, unlike }

class ReviewRepository {
  ReviewRepository(this._dio);

  final Dio _dio;

  Future<ReviewListResult> fetchRecent({
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) {
    return _fetchReviews(
      mode: "recent",
      year: year,
      semester: semester,
      offset: offset,
      limit: limit,
    );
  }

  Future<ReviewListResult> fetchHallOfFame({
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) {
    return _fetchReviews(
      mode: "hall-of-fame",
      year: year,
      semester: semester,
      offset: offset,
      limit: limit,
    );
  }

  Future<ReviewListResult> fetchCourse(
    int courseId, {
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) {
    return _fetchReviews(
      mode: "default",
      courseId: courseId,
      year: year,
      semester: semester,
      offset: offset,
      limit: limit,
    );
  }

  Future<List<Review>> fetchLiked(int userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      API_V2_LIKED_REVIEWS_URL.replaceFirst("{user_id}", userId.toString()),
    );
    final data = response.data as Map<String, dynamic>;
    return List<Review>.unmodifiable(
      (data["reviews"] as List<dynamic>).map(
        (review) => Review.fromV2Json(review as Map<String, dynamic>),
      ),
    );
  }

  Future<int> create({
    required int lectureId,
    required String content,
    required int grade,
    required int load,
    required int speech,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      API_V2_REVIEWS_URL,
      data: <String, dynamic>{
        "lectureId": lectureId,
        "content": content,
        "grade": grade,
        "load": load,
        "speech": speech,
      },
    );
    return (response.data as Map<String, dynamic>)["id"] as int;
  }

  Future<int> update({
    required int reviewId,
    required String content,
    required int grade,
    required int load,
    required int speech,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      API_V2_REVIEW_DETAIL_URL.replaceFirst("{id}", reviewId.toString()),
      data: <String, dynamic>{
        "content": content,
        "grade": grade,
        "load": load,
        "speech": speech,
      },
    );
    return (response.data as Map<String, dynamic>)["id"] as int;
  }

  Future<int> updateLiked({
    required int reviewId,
    required ReviewLikeAction action,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      API_V2_REVIEW_LIKED_URL.replaceFirst("{id}", reviewId.toString()),
      data: <String, dynamic>{"reviewId": reviewId, "action": action.name},
    );
    return (response.data as Map<String, dynamic>)["id"] as int;
  }

  Future<ReviewListResult> _fetchReviews({
    required String mode,
    int? courseId,
    int? year,
    int? semester,
    required int offset,
    required int limit,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      API_V2_REVIEWS_URL,
      queryParameters: <String, dynamic>{
        "mode": mode,
        if (courseId != null) "courseId": courseId,
        if (year != null) "year": year,
        if (semester != null) "semester": semester,
        "offset": offset,
        "limit": limit,
      },
    );
    return ReviewListResult.fromJson(response.data as Map<String, dynamic>);
  }
}
