import 'package:flutter/material.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/review.dart';

class LectureDetailModel extends ChangeNotifier {
  late Lecture _lecture;
  Lecture get lecture => _lecture;

  late Course _course;
  Course get course => _course;

  bool _isUpdateEnabled = false;
  bool get isUpdateEnabled => _isUpdateEnabled;

  bool _hasData = false;
  bool get hasData => _hasData;

  bool _loadFailed = false;
  bool get loadFailed => _loadFailed;

  int? _lectureId;
  bool _lastIsUpdateEnabled = false;

  late List<Review> _reviews;
  List<Review> get reviews => _reviews;

  Future<void> loadLecture(int lectureId, bool isUpdateEnabled) async {
    _lectureId = lectureId;
    _lastIsUpdateEnabled = isUpdateEnabled;
    _hasData = false;
    _loadFailed = false;
    notifyListeners();

    try {
      final response = await DioProvider().dio.get(
        API_LECTURE_URL + "/" + lectureId.toString(),
      );

      _lecture = Lecture.fromJson(response.data);
      _course = await getLectureCourse();
      _reviews = await getLectureReviews();
      _isUpdateEnabled = isUpdateEnabled;

      _hasData = true;
      notifyListeners();
    } catch (exception) {
      print(exception);
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

  Future<List<Review>> getLectureReviews() async {
    final response = await DioProvider().dio.get(
      API_LECTURE_RELATED_REVIEWS_URL.replaceFirst(
        "{id}",
        _lecture.id.toString(),
      ),
    );
    final rawReviews = response.data as List;
    return rawReviews.map((review) => Review.fromJson(review)).toList();
  }

  Future<Course> getLectureCourse() async {
    final response = await DioProvider().dio.get(
      API_COURSE_URL + "/" + _lecture.course.toString(),
    );
    return Course.fromJson(response.data);
  }

  Future<void> updateLectureReviews(Review review) async {
    int index = _reviews.indexOf(review);
    if (index > -1) {
      _reviews.removeAt(index);
      _reviews.insert(index, review);
    } else {
      _reviews.insert(0, review);
    }
    notifyListeners();
  }
}
