import "dart:async";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/models/course.dart";
import "package:otlplus/models/lecture.dart";
import "package:otlplus/models/review.dart";
import "package:otlplus/providers/course_detail_model.dart";
import "package:otlplus/providers/lecture_detail_model.dart";
import "package:otlplus/repositories/course_repository.dart";
import "package:otlplus/repositories/lecture_repository.dart";
import "package:otlplus/repositories/review_repository.dart";

import "../utils/samples.dart";

void main() {
  test(
    "course detail starts independent repository loads in parallel",
    () async {
      final courseRepository = _ControlledCourseRepository();
      final lectureRepository = _ControlledLectureRepository();
      final reviewRepository = _ControlledReviewRepository();
      final model = CourseDetailModel(
        courseRepository,
        lectureRepository,
        reviewRepository,
      );

      final load = model.loadCourse(SampleCourse.id);
      await Future<void>.delayed(Duration.zero);

      expect(model.isLoading, isTrue);
      expect(model.hasData, isFalse);
      expect(model.error, isNull);
      expect(courseRepository.detailIds, <int>[SampleCourse.id]);
      expect(lectureRepository.courseLectureIds, <int>[SampleCourse.id]);
      expect(reviewRepository.courseIds, <int>[SampleCourse.id]);

      courseRepository.detailRequests.single.complete(SampleCourse.shared);
      lectureRepository.courseLectureRequests.single.complete(<Lecture>[
        SampleLecture.shared,
      ]);
      reviewRepository.courseRequests.single.complete(
        _reviewResult(
          averageGrade: 4.25,
          averageLoad: 2.5,
          averageSpeech: 3.75,
        ),
      );
      await load;

      expect(model.isLoading, isFalse);
      expect(model.hasData, isTrue);
      expect(model.loadFailed, isFalse);
      expect(model.course.grade, 4.25);
      expect(model.course.load, 2.5);
      expect(model.course.speech, 3.75);
      expect(model.lectures, <Lecture>[SampleLecture.shared]);
      expect(model.reviews, <Review>[SampleReview.shared]);
      expect(model.selectedFilter, "ALL");
    },
  );

  test("course detail exposes repository failures and retry state", () async {
    final failure = StateError("course detail failed");
    final courseRepository = _ControlledCourseRepository();
    final lectureRepository = _ControlledLectureRepository();
    final reviewRepository = _ControlledReviewRepository();
    final model = CourseDetailModel(
      courseRepository,
      lectureRepository,
      reviewRepository,
    );

    final load = model.loadCourse(SampleCourse.id);
    await Future<void>.delayed(Duration.zero);
    courseRepository.detailRequests.single.completeError(failure);
    lectureRepository.courseLectureRequests.single.complete(<Lecture>[]);
    reviewRepository.courseRequests.single.complete(_reviewResult());
    await load;

    expect(model.isLoading, isFalse);
    expect(model.hasData, isFalse);
    expect(model.loadFailed, isTrue);
    expect(model.error, same(failure));

    final retry = model.retryLoad();
    await Future<void>.delayed(Duration.zero);
    expect(courseRepository.detailIds, <int>[SampleCourse.id, SampleCourse.id]);
    courseRepository.detailRequests.last.complete(SampleCourse.shared);
    lectureRepository.courseLectureRequests.last.complete(<Lecture>[]);
    reviewRepository.courseRequests.last.complete(_reviewResult());
    await retry;

    expect(model.isLoading, isFalse);
    expect(model.hasData, isTrue);
    expect(model.loadFailed, isFalse);
    expect(model.error, isNull);
  });

  test(
    "lecture detail overlaps retained v1 reviews with dependent course load",
    () async {
      final courseRepository = _ControlledCourseRepository();
      final lectureRepository = _ControlledLectureRepository();
      final model = LectureDetailModel(courseRepository, lectureRepository);

      final load = model.loadLecture(SampleLecture.id, true);
      await Future<void>.delayed(Duration.zero);

      expect(model.isLoading, isTrue);
      expect(lectureRepository.detailIds, <int>[SampleLecture.id]);
      expect(lectureRepository.relatedReviewIds, <int>[SampleLecture.id]);
      expect(courseRepository.detailIds, isEmpty);

      lectureRepository.detailRequests.single.complete(SampleLecture.shared);
      await Future<void>.delayed(Duration.zero);

      expect(courseRepository.detailIds, <int>[SampleCourse.id]);
      expect(model.isLoading, isTrue);

      courseRepository.detailRequests.single.complete(SampleCourse.shared);
      lectureRepository.relatedReviewRequests.single.complete(<Review>[
        SampleReview.shared,
      ]);
      await load;

      expect(model.isLoading, isFalse);
      expect(model.hasData, isTrue);
      expect(model.loadFailed, isFalse);
      expect(model.lecture, SampleLecture.shared);
      expect(model.course, SampleCourse.shared);
      expect(model.reviews, <Review>[SampleReview.shared]);
      expect(model.isUpdateEnabled, isTrue);
    },
  );

  test("lecture detail exposes retained route failures", () async {
    final failure = StateError("lecture detail failed");
    final courseRepository = _ControlledCourseRepository();
    final lectureRepository = _ControlledLectureRepository();
    final model = LectureDetailModel(courseRepository, lectureRepository);

    final load = model.loadLecture(SampleLecture.id, false);
    await Future<void>.delayed(Duration.zero);
    lectureRepository.detailRequests.single.completeError(failure);
    lectureRepository.relatedReviewRequests.single.complete(<Review>[]);
    await load;

    expect(model.isLoading, isFalse);
    expect(model.hasData, isFalse);
    expect(model.loadFailed, isTrue);
    expect(model.error, same(failure));
  });
}

ReviewListResult _reviewResult({
  double averageGrade = 0,
  double averageLoad = 0,
  double averageSpeech = 0,
}) {
  return ReviewListResult(
    reviews: <Review>[SampleReview.shared],
    averageGrade: averageGrade,
    averageLoad: averageLoad,
    averageSpeech: averageSpeech,
    department: null,
    totalCount: 1,
  );
}

class _ControlledCourseRepository extends CourseRepository {
  _ControlledCourseRepository() : super(Dio());

  final detailIds = <int>[];
  final detailRequests = <Completer<Course>>[];

  @override
  Future<Course> fetchDetail(int courseId) {
    detailIds.add(courseId);
    final request = Completer<Course>();
    detailRequests.add(request);
    return request.future;
  }
}

class _ControlledLectureRepository extends LectureRepository {
  _ControlledLectureRepository() : super(Dio());

  final detailIds = <int>[];
  final detailRequests = <Completer<Lecture>>[];
  final courseLectureIds = <int>[];
  final courseLectureRequests = <Completer<List<Lecture>>>[];
  final relatedReviewIds = <int>[];
  final relatedReviewRequests = <Completer<List<Review>>>[];

  @override
  Future<Lecture> fetchLegacyDetail(int lectureId) {
    detailIds.add(lectureId);
    final request = Completer<Lecture>();
    detailRequests.add(request);
    return request.future;
  }

  @override
  Future<List<Lecture>> fetchLegacyCourseLectures(int courseId) {
    courseLectureIds.add(courseId);
    final request = Completer<List<Lecture>>();
    courseLectureRequests.add(request);
    return request.future;
  }

  @override
  Future<List<Review>> fetchLegacyRelatedReviews(int lectureId) {
    relatedReviewIds.add(lectureId);
    final request = Completer<List<Review>>();
    relatedReviewRequests.add(request);
    return request.future;
  }
}

class _ControlledReviewRepository extends ReviewRepository {
  _ControlledReviewRepository() : super(Dio());

  final courseIds = <int>[];
  final courseRequests = <Completer<ReviewListResult>>[];

  @override
  Future<ReviewListResult> fetchCourse(
    int courseId, {
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) {
    courseIds.add(courseId);
    final request = Completer<ReviewListResult>();
    courseRequests.add(request);
    return request.future;
  }
}
