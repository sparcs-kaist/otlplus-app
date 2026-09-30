import "package:flutter/foundation.dart";
import "package:otlplus/models/course.dart";
import "package:otlplus/models/professor.dart";
import "package:otlplus/models/review.dart";
import "package:otlplus/repositories/course_repository.dart";
import "package:otlplus/repositories/review_repository.dart";

class CourseDetailModel extends ChangeNotifier {
  CourseDetailModel(
    CourseRepository courseRepository,
    ReviewRepository reviewRepository,
  ) : _courseRepository = courseRepository,
      _reviewRepository = reviewRepository;

  final CourseRepository _courseRepository;
  final ReviewRepository _reviewRepository;
  static const int _reviewPageSize = ReviewRepository.pageSize;

  late Course _course;
  Course get course => _course;

  String _selectedFilter = "ALL";
  String get selectedFilter => _selectedFilter;

  List<Professor> _professors = const <Professor>[];
  List<Professor> get professors => _professors;

  List<Review> _reviews = const <Review>[];
  List<Review> get reviews => _reviews;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMoreReviews = false;
  bool get isLoadingMoreReviews => _isLoadingMoreReviews;

  bool _hasMoreReviews = false;
  bool get hasMoreReviews => _hasMoreReviews;

  Object? _error;
  Object? get error => _error;

  bool _hasData = false;
  bool get hasData => _hasData;

  bool _loadFailed = false;
  bool get loadFailed => _loadFailed;

  int? _courseId;
  int _nextReviewOffset = 0;
  int _requestGeneration = 0;

  Future<void> loadCourse(int courseId) async {
    _courseId = courseId;
    final generation = ++_requestGeneration;
    _isLoading = true;
    _isLoadingMoreReviews = false;
    _hasMoreReviews = false;
    _nextReviewOffset = 0;
    _error = null;
    _hasData = false;
    _loadFailed = false;
    notifyListeners();

    try {
      final courseRequest = _courseRepository.fetchDetail(courseId);
      final reviewRequest = _reviewRepository.fetchCourse(
        courseId,
        offset: 0,
        limit: _reviewPageSize,
      );
      late Course course;
      late ReviewListResult reviewResult;

      await Future.wait<void>(<Future<void>>[
        courseRequest.then((value) {
          course = value;
        }),
        reviewRequest.then((value) {
          reviewResult = value;
        }),
      ]);
      if (generation != _requestGeneration) return;

      _course = course.withReviewAverages(
        grade: reviewResult.averageGrade,
        load: reviewResult.averageLoad,
        speech: reviewResult.averageSpeech,
        reviewCount: reviewResult.totalCount,
      );
      _professors = course.professors.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _reviews = List<Review>.unmodifiable(reviewResult.reviews);
      _nextReviewOffset = _reviewPageSize;
      _hasMoreReviews = reviewResult.reviews.length == _reviewPageSize;
      _selectedFilter = "ALL";
      _isLoading = false;
      _hasData = true;
      notifyListeners();
    } catch (caughtError) {
      if (generation != _requestGeneration) return;
      _error = caughtError;
      _isLoading = false;
      _hasData = false;
      _loadFailed = true;
      notifyListeners();
    }
  }

  Future<void> retryLoad() async {
    final courseId = _courseId;
    if (courseId != null) await loadCourse(courseId);
  }

  Future<void> loadMoreReviews() async {
    final courseId = _courseId;
    if (courseId == null ||
        _isLoading ||
        _isLoadingMoreReviews ||
        !_hasMoreReviews) {
      return;
    }

    final generation = _requestGeneration;
    final offset = _nextReviewOffset;
    _isLoadingMoreReviews = true;
    notifyListeners();

    try {
      final result = await _reviewRepository.fetchCourse(
        courseId,
        professorId: int.tryParse(_selectedFilter),
        offset: offset,
        limit: _reviewPageSize,
      );
      if (generation != _requestGeneration) return;

      _reviews = List<Review>.unmodifiable(<Review>[
        ..._reviews,
        ...result.reviews,
      ]);
      _nextReviewOffset = offset + _reviewPageSize;
      _hasMoreReviews = result.reviews.length == _reviewPageSize;
    } catch (caughtError) {
      if (generation != _requestGeneration) return;
      _error = caughtError;
    } finally {
      if (generation == _requestGeneration) {
        _isLoadingMoreReviews = false;
        notifyListeners();
      }
    }
  }

  void updateCourseReviews(Review review) {
    final reviews = _reviews.toList();
    final index = reviews.indexOf(review);
    if (index > -1) {
      reviews[index] = review;
    } else {
      reviews.insert(0, review);
    }
    _reviews = List<Review>.unmodifiable(reviews);
    notifyListeners();
  }

  Future<void> setFilter(String filter) async {
    final courseId = _courseId;
    if (courseId == null || filter == _selectedFilter) return;
    _selectedFilter = filter;
    final generation = ++_requestGeneration;
    _reviews = const [];
    _nextReviewOffset = 0;
    _hasMoreReviews = false;
    _isLoadingMoreReviews = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _reviewRepository.fetchCourse(
        courseId,
        professorId: int.tryParse(filter),
        offset: 0,
        limit: _reviewPageSize,
      );
      if (generation != _requestGeneration) return;
      _reviews = result.reviews;
      _course = _course.withReviewAverages(
        grade: result.averageGrade,
        load: result.averageLoad,
        speech: result.averageSpeech,
        reviewCount: result.totalCount,
      );
      _nextReviewOffset = _reviewPageSize;
      _hasMoreReviews = result.reviews.length == _reviewPageSize;
    } catch (error) {
      if (generation != _requestGeneration) return;
      _error = error;
    } finally {
      if (generation == _requestGeneration) {
        _isLoadingMoreReviews = false;
        notifyListeners();
      }
    }
  }
}
