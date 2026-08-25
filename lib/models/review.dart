import 'package:otlplus/models/nested_course.dart';
import 'package:otlplus/models/nested_lecture.dart';
import 'package:otlplus/models/professor.dart';

/// Normalizes the two wire representations of the deletion flag: the legacy
/// integer (`0`/`1`) and the v2 boolean. Anything else is a contract
/// violation and throws instead of silently reading as active.
bool _normalizeIsDeleted(Object? value) {
  if (value is bool) return value;
  if (value == 0) return false;
  if (value == 1) return true;
  throw ArgumentError.value(value, 'isDeleted', 'expected bool or int 0/1');
}

class Review {
  final int id;
  final NestedCourse course;
  final NestedLecture lecture;
  final String content;
  final int like;
  final bool isDeleted;
  final int grade;
  final int load;
  final int speech;
  final bool userspecificIsLiked;

  Review({
    required this.id,
    required this.course,
    required this.lecture,
    required this.content,
    required this.like,
    required Object isDeleted,
    required this.grade,
    required this.load,
    required this.speech,
    required this.userspecificIsLiked,
  }) : isDeleted = _normalizeIsDeleted(isDeleted);

  bool operator ==(Object other) =>
      identical(this, other) || (other is Review && other.id == id);

  int get hashCode => id.hashCode;

  Review.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      course = NestedCourse.fromJson(json['course']),
      lecture = NestedLecture.fromJson(json['lecture']),
      content = json['content'],
      like = json['like'],
      isDeleted = _normalizeIsDeleted(json['is_deleted']),
      grade = json['grade'],
      load = json['load'],
      speech = json['speech'],
      userspecificIsLiked = json['userspecific_is_liked'];

  factory Review.fromV2Json(Map<String, dynamic> json) {
    final courseId = json['courseId'] as int;
    final courseName = json['courseName'] as String;
    final professors = (json['professors'] as List<dynamic>)
        .map((professorJson) {
          final professor = professorJson as Map<String, dynamic>;
          final name = professor['name'] as String;
          return Professor(
            name: name,
            nameEn: name,
            professorId: professor['id'] as int,
            reviewTotalWeight: 0,
          );
        })
        .toList(growable: false);

    return Review(
      id: json['id'] as int,
      course: NestedCourse(
        id: courseId,
        oldCode: '',
        type: '',
        typeEn: '',
        title: courseName,
        titleEn: courseName,
        summary: '',
        reviewTotalWeight: 0,
      ),
      lecture: NestedLecture(
        id: json['lectureId'] as int,
        title: courseName,
        titleEn: courseName,
        course: courseId,
        oldCode: '',
        classNo: '',
        year: json['year'] as int,
        semester: json['semester'] as int,
        code: '',
        department: 0,
        departmentCode: '',
        departmentName: '',
        departmentNameEn: '',
        type: '',
        typeEn: '',
        limit: 0,
        numPeople: 0,
        isEnglish: false,
        credit: 0,
        creditAu: 0,
        commonTitle: courseName,
        commonTitleEn: courseName,
        classTitle: '',
        classTitleEn: '',
        reviewTotalWeight: 0,
        professors: professors,
      ),
      content: json['content'] as String,
      like: json['like'] as int,
      isDeleted: _normalizeIsDeleted(json['isDeleted']),
      grade: json['grade'] as int,
      load: json['load'] as int,
      speech: json['speech'] as int,
      userspecificIsLiked: json['likedByUser'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['course'] = this.course.toJson();
    data['lecture'] = this.lecture.toJson();
    data['content'] = this.content;
    data['like'] = this.like;
    data['is_deleted'] = this.isDeleted ? 1 : 0;
    data['grade'] = this.grade;
    data['load'] = this.load;
    data['speech'] = this.speech;
    data['userspecific_is_liked'] = this.userspecificIsLiked;
    return data;
  }
}
