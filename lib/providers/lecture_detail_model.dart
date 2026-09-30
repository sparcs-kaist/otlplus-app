import "package:flutter/foundation.dart";
import "package:otlplus/models/course.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/models/review.dart";
import "package:otlplus/repositories/course_repository.dart";
import "package:otlplus/repositories/lecture_repository.dart";
import "package:otlplus/repositories/review_repository.dart";

class LectureDetailModel extends ChangeNotifier {
  LectureDetailModel(
    CourseRepository courseRepository,
    LectureRepository lectureRepository,
    ReviewRepository reviewRepository,
  ) : _courseRepository = courseRepository,
      _lectureRepository = lectureRepository,
      _reviewRepository = reviewRepository;

  final CourseRepository _courseRepository;
  final LectureRepository _lectureRepository;
  final ReviewRepository _reviewRepository;

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

  Lecture? _sourceLecture;
  Future<Lecture> Function()? _historyLoader;
  bool _lastIsUpdateEnabled = false;
  int _requestGeneration = 0;

  Future<void> loadLecture(Lecture lecture, bool isUpdateEnabled) {
    _sourceLecture = lecture;
    _historyLoader = null;
    return _load(() async => lecture, isUpdateEnabled);
  }

  Future<void> loadHistoryLecture(
    Course course,
    CourseHistory history,
    CourseHistoryClass entry,
  ) {
    _sourceLecture = null;
    _historyLoader = () => _lectureRepository.fetchHistoryDetail(
      lectureId: entry.lectureId,
      courseId: course.id,
      code: course.oldCode,
      year: history.year,
      semester: history.semester,
    );
    return _load(_historyLoader!, false);
  }

  Future<List<Review>> _fetchReviews(Lecture lecture) async {
    final professorIds = lecture.professors.map((p) => p.professorId).toSet();
    final results = await Future.wait(
      (professorIds.isEmpty ? <int?>[null] : professorIds.cast<int?>()).map((
        professorId,
      ) async {
        final reviews = <Review>[];
        for (var offset = 0; ; offset += 100) {
          final result = await _reviewRepository.fetchCourse(
            lecture.course,
            professorId: professorId,
            offset: offset,
            limit: 100,
          );
          reviews.addAll(result.reviews);
          if (reviews.length >= result.totalCount ||
              result.reviews.length < 100)
            break;
        }
        return reviews;
      }),
    );
    final byId = <int, Review>{};
    for (final reviews in results) {
      for (final review in reviews) {
        byId.putIfAbsent(review.id, () => review);
      }
    }
    return byId.values.toList(growable: false);
  }

  Future<void> _load(
    Future<Lecture> Function() lectureLoader,
    bool isUpdateEnabled,
  ) async {
    _lastIsUpdateEnabled = isUpdateEnabled;
    final generation = ++_requestGeneration;
    _isLoading = true;
    _error = null;
    _hasData = false;
    _loadFailed = false;
    notifyListeners();
    try {
      final lecture = await lectureLoader();
      late Course course;
      late List<Review> reviews;
      await Future.wait<void>([
        _courseRepository.fetchDetail(lecture.course).then((value) {
          course = value;
        }),
        _fetchReviews(lecture).then((value) {
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
    final source = _sourceLecture;
    if (source != null) {
      await loadLecture(source, _lastIsUpdateEnabled);
    } else if (_historyLoader != null) {
      await _load(_historyLoader!, false);
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
