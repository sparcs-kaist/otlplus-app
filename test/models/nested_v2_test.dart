import 'package:otlplus/models/department.dart';
import 'package:otlplus/models/nested_course.dart';
import 'package:otlplus/models/nested_lecture.dart';
import 'package:otlplus/models/professor.dart';
import 'package:test/test.dart';

void main() {
  test('parses v2 department and professor Basic shapes', () {
    final department = Department.fromV2Json({'id': 1, 'name': '전산학부'});
    final professor = Professor.fromV2Json({'id': 2, 'name': '홍길동'});

    expect(department.nameEn, '전산학부');
    expect(department.code, '');
    expect(professor.professorId, 2);
    expect(professor.nameEn, '홍길동');
    expect(professor.reviewTotalWeight, 0);
  });

  test('parses v2 nested course with safe legacy defaults', () {
    final course = NestedCourse.fromV2Json({
      'id': 10,
      'code': 'CS101',
      'name': '자료구조',
      'type': '전공필수',
      'department': {'id': 1, 'name': '전산학부'},
    });

    expect(course.id, 10);
    expect(course.titleEn, '자료구조');
    expect(course.typeEn, '전공필수');
    expect(course.summary, '');
    expect(course.department?.nameEn, '전산학부');
    expect(course.reviewTotalWeight, 0);
  });

  test('parses v2 review Basic nested lecture', () {
    final lecture = NestedLecture.fromV2Json({
      'lectureId': 20,
      'courseId': 10,
      'courseName': '자료구조',
      'subtitle': '분반 A',
      'department': {'id': 1, 'name': '전산학부'},
      'year': 2026,
      'semester': 1,
      'professors': [
        {'id': 2, 'name': '홍길동'},
      ],
      'isEnglish': null,
    });

    expect(lecture.id, 20);
    expect(lecture.course, 10);
    expect(lecture.titleEn, '자료구조');
    expect(lecture.commonTitleEn, '자료구조');
    expect(lecture.classTitleEn, '분반 A');
    expect(lecture.departmentNameEn, '전산학부');
    expect(lecture.year, 2026);
    expect(lecture.professors.single.professorId, 2);
    expect(lecture.isEnglish, false);
    expect(lecture.classNo, '');
    expect(lecture.reviewTotalWeight, 0);
  });

  test('rejects malformed required v2 nested data', () {
    expect(
      () => Department.fromV2Json({'id': 0, 'name': '전산학부'}),
      throwsFormatException,
    );
    expect(
      () => Professor.fromV2Json({'id': 1, 'name': ' '}),
      throwsFormatException,
    );
    expect(() => NestedCourse.fromV2Json({'id': 1}), throwsFormatException);
    expect(
      () => NestedLecture.fromV2Json({
        'lectureId': 20,
        'courseId': 10,
        'courseName': '자료구조',
      }),
      throwsFormatException,
    );
  });
}
