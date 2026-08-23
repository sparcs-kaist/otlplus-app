import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/models/professor.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/repositories/course_repository.dart';
import 'package:otlplus/repositories/department_repository.dart';

void main() {
  test('courses getter returns an unmodifiable snapshot', () async {
    final sourceCourses = <Course>[_course(1)];
    final model = CourseSearchModel(
      _CourseRepository(sourceCourses),
      _DepartmentRepository(),
    );
    model.setSearchText('course');

    expect(await model.courseSearch(), isTrue);
    await Future<void>.delayed(Duration.zero);
    final firstRead = model.courses!;

    expect(() => firstRead.add(_course(2)), throwsUnsupportedError);
    sourceCourses.add(_course(3));
    expect(firstRead.map((course) => course.id), <int>[1]);
    expect(model.courses!.map((course) => course.id), <int>[1, 3]);
    expect(identical(firstRead, model.courses), isFalse);

    model.resetCourseFilter();
    expect(model.courses, isNull);
  });
}

class _CourseRepository extends CourseRepository {
  _CourseRepository(this.courses) : super(Dio());

  final List<Course> courses;

  @override
  Future<CourseSearchResult> search(CourseSearchQuery query) async {
    return CourseSearchResult(courses: courses, totalCount: courses.length);
  }
}

class _DepartmentRepository extends DepartmentRepository {
  _DepartmentRepository() : super(Dio());

  @override
  Future<List<int>> resolveFilterCodes(Iterable<String> filterCodes) async {
    return const <int>[];
  }
}

Course _course(int id) {
  return Course(
    id: id,
    oldCode: 'TEST.$id',
    type: 'Type',
    typeEn: 'Type',
    title: 'Course $id',
    titleEn: 'Course $id',
    summary: '',
    reviewTotalWeight: 0,
    professors: <Professor>[],
    grade: 0,
    load: 0,
    speech: 0,
    userspecificIsRead: false,
  );
}
