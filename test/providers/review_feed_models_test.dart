import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/latest_reviews_model.dart';
import 'package:otlplus/providers/liked_review_model.dart';
import 'package:otlplus/repositories/review_repository.dart';

import '../utils/samples.dart';

void main() {
  test('review feed getters never start network requests', () async {
    final repository = _FakeReviewRepository();
    final latest = LatestReviewsModel(repository);
    final liked = LikedReviewModel(repository);
    final hallOfFame = HallOfFameModel(repository);

    expect(latest.latestReviews, isEmpty);
    expect(liked.likedReviews, isEmpty);
    expect(hallOfFame.hallOfFame, isEmpty);
    await Future<void>.delayed(Duration.zero);

    expect(repository.recentRequests, isEmpty);
    expect(repository.likedUserIds, isEmpty);
    expect(repository.hallOfFameRequests, isEmpty);
  });

  test('latest reviews load and paginate with explicit offsets', () async {
    final repository = _FakeReviewRepository(
      recentResults: <ReviewListResult>[
        _result(reviewCount: 10, totalCount: 12),
        _result(reviewCount: 2, totalCount: 12),
      ],
    );
    final model = LatestReviewsModel(repository);

    await model.load();

    expect(model.latestReviews, hasLength(10));
    expect(model.hasMore, isTrue);
    expect(model.error, isNull);
    expect(repository.recentRequests, <_PageRequest>[
      const _PageRequest(offset: 0, limit: 10),
    ]);

    await model.loadMore();
    await model.loadMore();

    expect(model.latestReviews, hasLength(12));
    expect(model.hasMore, isFalse);
    expect(repository.recentRequests, <_PageRequest>[
      const _PageRequest(offset: 0, limit: 10),
      const _PageRequest(offset: 10, limit: 10),
    ]);
  });

  test('hall of fame forwards semesters 1 through 4 and paginates', () async {
    final repository = _FakeReviewRepository(
      hallOfFameResults: <ReviewListResult>[
        ...List<ReviewListResult>.generate(
          4,
          (_) => _result(reviewCount: 10, totalCount: 10),
        ),
        _result(reviewCount: 10, totalCount: 12),
        _result(reviewCount: 2, totalCount: 12),
      ],
    );
    final model = HallOfFameModel(repository);

    for (var semester = 1; semester <= 4; semester++) {
      model.setSemester(_semester(semester));
      await model.refresh();
    }

    expect(
      repository.hallOfFameRequests.take(4).map((request) => request.semester),
      <int>[1, 2, 3, 4],
    );

    model.setSemester(_semester(4));
    await model.refresh();
    await model.loadMore();

    expect(model.hallOfFame, hasLength(12));
    expect(model.hasMore, isFalse);
    expect(
      repository.hallOfFameRequests.last,
      const _PageRequest(offset: 10, limit: 10, year: 2024, semester: 4),
    );
  });

  test(
    'liked reviews paginate in memory after one repository request',
    () async {
      final repository = _FakeReviewRepository(
        likedResult: List<Review>.filled(23, SampleReview.shared),
      );
      final model = LikedReviewModel(repository);

      await model.load(42);

      expect(model.likedReviews, hasLength(10));
      expect(model.hasMore, isTrue);
      expect(repository.likedUserIds, <int>[42]);

      await model.loadMore();
      expect(model.likedReviews, hasLength(20));
      expect(repository.likedUserIds, <int>[42]);

      await model.loadMore();
      await model.loadMore();
      expect(model.likedReviews, hasLength(23));
      expect(model.hasMore, isFalse);
      expect(repository.likedUserIds, <int>[42]);
    },
  );

  test(
    'latest liked user request wins when responses complete out of order',
    () async {
      final repository = _DeferredLikedReviewRepository();
      final model = LikedReviewModel(repository);
      var notificationCount = 0;
      model.addListener(() {
        notificationCount++;
      });

      final user42Load = model.load(42);
      final user43Load = model.load(43);
      await Future<void>.delayed(Duration.zero);

      expect(repository.userIds, <int>[42, 43]);

      repository.complete(43, <Review>[_review(43)]);
      await user43Load;

      expect(model.likedReviews.single.id, 43);
      expect(model.isLoading, isFalse);
      expect(model.error, isNull);
      expect(notificationCount, 3);

      repository.complete(42, <Review>[_review(42)]);
      await user42Load;

      expect(model.likedReviews.single.id, 43);
      expect(model.isLoading, isFalse);
      expect(model.error, isNull);
      expect(notificationCount, 3);
    },
  );

  test('failed loads expose an error and always clear loading state', () async {
    final failure = StateError('failed');
    final repository = _FakeReviewRepository(recentError: failure);
    final model = LatestReviewsModel(repository);

    await model.load();

    expect(model.isLoading, isFalse);
    expect(model.error, same(failure));
    expect(model.latestReviews, isEmpty);
  });
}

ReviewListResult _result({required int reviewCount, required int totalCount}) {
  return ReviewListResult(
    reviews: List<Review>.filled(reviewCount, SampleReview.shared),
    averageGrade: 0,
    averageLoad: 0,
    averageSpeech: 0,
    department: null,
    totalCount: totalCount,
  );
}

Review _review(int id) {
  return Review(
    id: id,
    course: SampleReview.shared.course,
    lecture: SampleReview.shared.lecture,
    content: SampleReview.shared.content,
    like: SampleReview.shared.like,
    isDeleted: SampleReview.shared.isDeleted,
    grade: SampleReview.shared.grade,
    load: SampleReview.shared.load,
    speech: SampleReview.shared.speech,
    userspecificIsLiked: SampleReview.shared.userspecificIsLiked,
  );
}

Semester _semester(int semester) {
  return Semester(
    year: 2024,
    semester: semester,
    beginning: DateTime(2024),
    end: DateTime(2025),
  );
}

class _PageRequest {
  const _PageRequest({
    required this.offset,
    required this.limit,
    this.year,
    this.semester,
  });

  final int offset;
  final int limit;
  final int? year;
  final int? semester;

  @override
  bool operator ==(Object other) {
    return other is _PageRequest &&
        other.offset == offset &&
        other.limit == limit &&
        other.year == year &&
        other.semester == semester;
  }

  @override
  int get hashCode => Object.hash(offset, limit, year, semester);
}

class _DeferredLikedReviewRepository extends ReviewRepository {
  _DeferredLikedReviewRepository() : super(Dio());

  final List<int> userIds = <int>[];
  final Map<int, Completer<List<Review>>> _requests =
      <int, Completer<List<Review>>>{};

  @override
  Future<List<Review>> fetchLiked(int userId) {
    userIds.add(userId);
    return (_requests[userId] ??= Completer<List<Review>>()).future;
  }

  void complete(int userId, List<Review> reviews) {
    _requests[userId]!.complete(reviews);
  }
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({
    List<ReviewListResult>? recentResults,
    List<ReviewListResult>? hallOfFameResults,
    List<Review>? likedResult,
    this.recentError,
  }) : recentResults = recentResults ?? <ReviewListResult>[],
       hallOfFameResults = hallOfFameResults ?? <ReviewListResult>[],
       likedResult = likedResult ?? <Review>[],
       super(Dio());

  final List<ReviewListResult> recentResults;
  final List<ReviewListResult> hallOfFameResults;
  final List<Review> likedResult;
  final Object? recentError;
  final List<_PageRequest> recentRequests = <_PageRequest>[];
  final List<_PageRequest> hallOfFameRequests = <_PageRequest>[];
  final List<int> likedUserIds = <int>[];
  int _recentResultIndex = 0;
  int _hallOfFameResultIndex = 0;

  @override
  Future<ReviewListResult> fetchRecent({
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) async {
    recentRequests.add(
      _PageRequest(
        offset: offset,
        limit: limit,
        year: year,
        semester: semester,
      ),
    );
    final error = recentError;
    if (error != null) throw error;
    return recentResults[_recentResultIndex++];
  }

  @override
  Future<ReviewListResult> fetchHallOfFame({
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) async {
    hallOfFameRequests.add(
      _PageRequest(
        offset: offset,
        limit: limit,
        year: year,
        semester: semester,
      ),
    );
    return hallOfFameResults[_hallOfFameResultIndex++];
  }

  @override
  Future<List<Review>> fetchLiked(int userId) async {
    likedUserIds.add(userId);
    return likedResult;
  }
}
