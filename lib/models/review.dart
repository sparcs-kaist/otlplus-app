import 'package:otlplus/models/nested_course.dart';
import 'package:otlplus/models/nested_lecture.dart';

class Review {
  final int id;
  final NestedCourse course;
  final NestedLecture lecture;
  final String content;
  final int like;
  final int isDeleted;
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
    required this.isDeleted,
    required this.grade,
    required this.load,
    required this.speech,
    required this.userspecificIsLiked,
  });

  bool operator ==(Object other) =>
      identical(this, other) || (other is Review && other.id == id);

  int get hashCode => id.hashCode;

  Review.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      course = NestedCourse.fromJson(json['course']),
      lecture = NestedLecture.fromJson(json['lecture']),
      content = json['content'],
      like = json['like'],
      isDeleted = json['is_deleted'],
      grade = json['grade'],
      load = json['load'],
      speech = json['speech'],
      userspecificIsLiked = json['userspecific_is_liked'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['course'] = this.course.toJson();
    data['lecture'] = this.lecture.toJson();
    data['content'] = this.content;
    data['like'] = this.like;
    data['is_deleted'] = this.isDeleted;
    data['grade'] = this.grade;
    data['load'] = this.load;
    data['speech'] = this.speech;
    data['userspecific_is_liked'] = this.userspecificIsLiked;
    return data;
  }
}
