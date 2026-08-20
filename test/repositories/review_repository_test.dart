import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/review.dart";
import "package:otlplus/repositories/review_repository.dart";

import "../utils/fake_http.dart";

class CapturingHttpAdapter extends FakeHttpAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return super.fetch(options, requestStream, cancelFuture);
  }
}

void main() {
  late CapturingHttpAdapter adapter;
  late ReviewRepository repository;
  late Map<String, dynamic> fixture;
  late Map<String, dynamic> reviewJson;

  setUp(() async {
    fixture =
        jsonDecode(
              await File("test/fixtures/v2/reviews_recent.json").readAsString(),
            )
            as Map<String, dynamic>;
    reviewJson =
        (fixture["reviews"] as List<dynamic>).single as Map<String, dynamic>;
    adapter = CapturingHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: "http://test/"))
      ..httpClientAdapter = adapter;
    repository = ReviewRepository(dio);
  });

  test("fetchRecent maps mode, semester filters, and pagination", () async {
    adapter.register(
      "GET",
      "/$API_V2_REVIEWS_URL"
          "?limit=20&mode=recent&offset=10&semester=3&year=2026",
      fixture,
    );

    final result = await repository.fetchRecent(
      year: 2026,
      semester: 3,
      offset: 10,
      limit: 20,
    );

    expect(result.totalCount, 1);
    expect(result.reviews, hasLength(1));
  });

  test("fetchHallOfFame uses the v2 hall-of-fame mode", () async {
    adapter.register(
      "GET",
      "/$API_V2_REVIEWS_URL"
          "?limit=10&mode=hall-of-fame&offset=0&semester=1&year=2025",
      fixture,
    );

    await repository.fetchHallOfFame(year: 2025, semester: 1);

    expect(adapter.requests.single.queryParameters, <String, dynamic>{
      "mode": "hall-of-fame",
      "year": 2025,
      "semester": 1,
      "offset": 0,
      "limit": 10,
    });
  });

  test("fetchCourse maps the default mode and course ID", () async {
    adapter.register(
      "GET",
      "/$API_V2_REVIEWS_URL"
          "?courseId=24732&limit=10&mode=default&offset=0",
      fixture,
    );

    await repository.fetchCourse(24732);

    expect(adapter.requests.single.queryParameters, <String, dynamic>{
      "mode": "default",
      "courseId": 24732,
      "offset": 0,
      "limit": 10,
    });
  });

  test("fetchLiked replaces the user ID in the v2 path", () async {
    final path = API_V2_LIKED_REVIEWS_URL.replaceFirst("{user_id}", "42");
    adapter.register("GET", "/$path", fixture);

    final reviews = await repository.fetchLiked(42);

    expect(reviews.single.id, 1);
    expect(adapter.requests.single.uri.path, "/$path");
    expect(adapter.requests.single.queryParameters, isEmpty);
  });

  test("parses response metadata and compatibility review fields", () async {
    adapter.register(
      "GET",
      "/$API_V2_REVIEWS_URL?limit=10&mode=recent&offset=0",
      fixture,
    );

    final result = await repository.fetchRecent();
    final review = result.reviews.single;

    expect(result.averageGrade, 4);
    expect(result.averageLoad, 3);
    expect(result.averageSpeech, 4);
    expect(result.department?.id, 24356);
    expect(result.department?.name, "AX학과");
    expect(result.totalCount, 1);
    expect(review.id, 1);
    expect(review.course.id, 24732);
    expect(review.course.title, "AI모델 및 알고리즘의 이해");
    expect(review.course.titleEn, review.course.title);
    expect(review.course.oldCode, "");
    expect(review.lecture.id, 1929802);
    expect(review.lecture.course, 24732);
    expect(review.lecture.title, review.course.title);
    expect(review.lecture.year, 2026);
    expect(review.lecture.semester, 3);
    expect(review.lecture.professors.single.professorId, 229);
    expect(review.lecture.professors.single.name, "문일철");
    expect(review.lecture.professors.single.nameEn, "문일철");
    expect(review.lecture.oldCode, "");
    expect(review.lecture.department, 0);
    expect(review.content, "fixture");
    expect(review.like, 0);
    expect(review.grade, 4);
    expect(review.load, 3);
    expect(review.speech, 4);
    expect(review.isDeleted, 0);
    expect(review.userspecificIsLiked, isFalse);
  });

  test("normalizes a deleted v2 review boolean to the legacy integer", () {
    final deletedReview = <String, dynamic>{...reviewJson, "isDeleted": true};

    final review = Review.fromV2Json(deletedReview);

    expect(review.isDeleted, 1);
  });

  test("create posts the v2 review body", () async {
    adapter.register("POST", "/$API_V2_REVIEWS_URL", <String, dynamic>{
      "id": 1,
    });

    final reviewId = await repository.create(
      lectureId: 1929802,
      content: "new review",
      grade: 5,
      load: 2,
      speech: 4,
    );

    expect(reviewId, 1);
    expect(adapter.requests.single.method, "POST");
    expect(adapter.requests.single.uri.path, "/$API_V2_REVIEWS_URL");
    expect(adapter.requests.single.data, <String, dynamic>{
      "lectureId": 1929802,
      "content": "new review",
      "grade": 5,
      "load": 2,
      "speech": 4,
    });
  });

  test("update puts editable fields to the v2 detail path", () async {
    final path = API_V2_REVIEW_DETAIL_URL.replaceFirst("{id}", "1");
    adapter.register("PUT", "/$path", <String, dynamic>{"id": 1});

    final reviewId = await repository.update(
      reviewId: 1,
      content: "updated review",
      grade: 3,
      load: 4,
      speech: 5,
    );

    expect(reviewId, 1);
    expect(adapter.requests.single.method, "PUT");
    expect(adapter.requests.single.uri.path, "/$path");
    expect(adapter.requests.single.data, <String, dynamic>{
      "content": "updated review",
      "grade": 3,
      "load": 4,
      "speech": 5,
    });
  });

  test("updateLiked patches reviewId and action to the liked path", () async {
    final path = API_V2_REVIEW_LIKED_URL.replaceFirst("{id}", "1");
    adapter.register("PATCH", "/$path", <String, dynamic>{"id": 1});

    final reviewId = await repository.updateLiked(
      reviewId: 1,
      action: ReviewLikeAction.unlike,
    );

    expect(reviewId, 1);
    expect(adapter.requests.single.method, "PATCH");
    expect(adapter.requests.single.uri.path, "/$path");
    expect(adapter.requests.single.data, <String, dynamic>{
      "reviewId": 1,
      "action": "unlike",
    });
  });
}
