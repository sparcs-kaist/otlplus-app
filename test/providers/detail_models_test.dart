import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/repositories/course_repository.dart';
import 'package:otlplus/repositories/lecture_repository.dart';
import 'package:otlplus/repositories/review_repository.dart';

import '../utils/samples.dart';

void main() {
  test(
    'course detail uses v2 history and independent course/review loads',
    () async {
      final courses = _Courses();
      final reviews = _Reviews();
      final model = CourseDetailModel(courses, reviews);
      final load = model.loadCourse(SampleCourse.id);
      expect(courses.ids, [SampleCourse.id]);
      expect(reviews.requests.single, (SampleCourse.id, null, 0, 100));
      final course = Course.fromV2Json(
        jsonDecode(
          await File('test/fixtures/v2/course_detail.json').readAsString(),
        ),
      );
      courses.pending.single.complete(course);
      reviews.pending.single.complete(_result(1));
      await load;
      expect(model.hasData, isTrue);
      expect(model.course.history, same(course.history));
      expect(model.professors, isNotEmpty);
      expect(model.course.grade, 4);
      expect(model.course.reviewTotalWeight, 1);
    },
  );

  test(
    'professor filtering restarts server pagination and ignores stale pages',
    () async {
      final courses = _Courses();
      final reviews = _Reviews();
      final model = CourseDetailModel(courses, reviews);
      final load = model.loadCourse(SampleCourse.id);
      courses.pending.single.complete(SampleCourse.shared);
      reviews.pending.single.complete(_result(100));
      await load;
      final oldPage = model.loadMoreReviews();
      final filter = model.setFilter('229');
      expect(reviews.requests, [
        (SampleCourse.id, null, 0, 100),
        (SampleCourse.id, null, 100, 100),
        (SampleCourse.id, 229, 0, 100),
      ]);
      reviews.pending.last.complete(_result(100));
      await filter;
      reviews.pending[1].complete(_result(100));
      await oldPage;
      expect(model.reviews, hasLength(100));
      final nextPage = model.loadMoreReviews();
      expect(reviews.requests.last, (SampleCourse.id, 229, 100, 100));
      reviews.pending.last.complete(_result(2));
      await nextPage;
      expect(model.reviews, hasLength(102));
      expect(model.hasMoreReviews, isFalse);
      final all = model.setFilter('ALL');
      expect(reviews.requests.last, (SampleCourse.id, null, 0, 100));
      reviews.pending.last.complete(_result(1));
      await all;
    },
  );

  test(
    'lecture detail shares the supplied lecture and uses all-year professor reviews',
    () async {
      final courses = _Courses();
      final reviews = _Reviews();
      final model = LectureDetailModel(
        courses,
        LectureRepository(Dio()),
        reviews,
      );
      final load = model.loadLecture(SampleLecture.shared, true);
      await Future<void>.delayed(Duration.zero);
      expect(courses.ids, [SampleLecture.shared.course]);
      expect(
        reviews.requests,
        SampleLecture.shared.professors
            .map((p) => (SampleLecture.shared.course, p.professorId, 0, 100))
            .toList(),
      );
      courses.pending.single.complete(SampleCourse.shared);
      for (final request in reviews.pending) {
        request.complete(_result(1));
      }
      await load;
      expect(model.lecture, same(SampleLecture.shared));
      expect(
        model.reviews,
        hasLength(1),
      ); // Co-taught reviews are deduplicated.
      expect(model.isUpdateEnabled, isTrue);
    },
  );

  test(
    'lecture review failure exposes retry without fetching v1 detail',
    () async {
      final courses = _Courses();
      final reviews = _Reviews();
      final model = LectureDetailModel(
        courses,
        LectureRepository(Dio()),
        reviews,
      );
      final load = model.loadLecture(SampleLecture.shared, false);
      await Future<void>.delayed(Duration.zero);
      courses.pending.single.complete(SampleCourse.shared);
      final failure = StateError('reviews failed');
      for (final request in reviews.pending) {
        request.completeError(failure);
      }
      await load;
      expect(model.loadFailed, isTrue);
      expect(model.error, same(failure));
      final oldCount = reviews.pending.length;
      final retry = model.retryLoad();
      await Future<void>.delayed(Duration.zero);
      courses.pending.last.complete(SampleCourse.shared);
      for (final request in reviews.pending.skip(oldCount)) {
        request.complete(_result(1));
      }
      await retry;
      expect(model.hasData, isTrue);
      expect(model.lecture, same(SampleLecture.shared));
    },
  );
}

ReviewListResult _result(int count) => ReviewListResult(
  reviews: List<Review>.filled(count, SampleReview.shared),
  averageGrade: 4,
  averageLoad: 3,
  averageSpeech: 2,
  department: null,
  totalCount: count,
);

class _Courses extends CourseRepository {
  _Courses() : super(Dio());
  final ids = <int>[];
  final pending = <Completer<Course>>[];
  @override
  Future<Course> fetchDetail(int courseId) {
    ids.add(courseId);
    final request = Completer<Course>();
    pending.add(request);
    return request.future;
  }
}

class _Reviews extends ReviewRepository {
  _Reviews() : super(Dio());
  final requests = <(int, int?, int, int)>[];
  final pending = <Completer<ReviewListResult>>[];
  @override
  Future<ReviewListResult> fetchCourse(
    int courseId, {
    int? professorId,
    int? year,
    int? semester,
    int offset = 0,
    int limit = 100,
  }) {
    expect(year, isNull);
    expect(semester, isNull);
    requests.add((courseId, professorId, offset, limit));
    final request = Completer<ReviewListResult>();
    pending.add(request);
    return request.future;
  }
}
