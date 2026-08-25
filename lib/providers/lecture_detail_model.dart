import "package:flutter/foundation.dart";
import "package:otlplus/models/course.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/models/review.dart";
import "package:otlplus/repositories/course_repository.dart";
import "package:otlplus/repositories/lecture_repository.dart";

class LectureDetailModel extends ChangeNotifier {
  LectureDetailModel(
    CourseRepository courseRepository,
    LectureRepository lectureRepository,
  ) : _courseRepository = courseRepository,
      _lectureRepository = lectureRepository;

  final CourseRepository _courseRepository;
  final LectureRepository _lectureRepository;

  late Lecture _lecture;
  Lecture get lecture => _lecture;

  late Course _course;
  Course get course => _course;

  List<Review> _reviews = const <Review>[];
  List<Review> get reviews => _reviews;

  bool _isUpdateEnabled = false;
  bool get isUpdateEnabled => _isUpdateEnabled;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Object? _error;
  Object? get error => _error;

  bool _hasData = false;
  bool get hasData => _hasData;

  bool _loadFailed = false;
  bool get loadFailed => _loadFailed;

  int? _lectureId;
  bool _lastIsUpdateEnabled = false;
  int _requestGeneration = 0;

  Future<void> loadLecture(int lectureId, bool isUpdateEnabled) async {
    _lectureId = lectureId;
    _lastIsUpdateEnabled = isUpdateEnabled;
    final generation = ++_requestGeneration;
    _isLoading = true;
    _error = null;
    _hasData = false;
    _loadFailed = false;
    notifyListeners();

    try {
      final lectureRequest = _lectureRepository.fetchLegacyDetail(lectureId);
      final reviewRequest = _lectureRepository.fetchLegacyRelatedReviews(
        lectureId,
      );
      final courseRequest = lectureRequest.then(
        (lecture) => _courseRepository.fetchDetail(lecture.course),
      );
      late Lecture lecture;
      late Course course;
      late List<Review> reviews;

      await Future.wait<void>(<Future<void>>[
        lectureRequest.then((value) {
          lecture = value;
        }),
        courseRequest.then((value) {
          course = value;
        }),
        reviewRequest.then((value) {
          reviews = value;
        }),
      ]);
      if (generation != _requestGeneration) return;

      _lecture = lecture;
      _course = course;
      _reviews = List<Review>.unmodifiable(reviews);
      _isUpdateEnabled = isUpdateEnabled;
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
    final lectureId = _lectureId;
    if (lectureId != null) {
      await loadLecture(lectureId, _lastIsUpdateEnabled);
    }
  }

  void updateLectureReviews(Review review) {
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
}
