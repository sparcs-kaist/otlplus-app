import 'package:otlplus/models/department.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/review.dart';

class User {
  final int id;
  final String email;
  final String studentId;
  final String firstName;
  final String lastName;
  late List<Department> majors;
  late List<Department> departments;
  late List<Lecture> myTimetableLectures;
  late List<Department>? favoriteDepartments;
  late List<Lecture> reviewWritableLectures;
  late List<Review> reviews;

  User({
    required this.id,
    required this.email,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.majors,
    required this.departments,
    required this.myTimetableLectures,
    this.favoriteDepartments,
    required this.reviewWritableLectures,
    required this.reviews,
  });

  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  int get hashCode => id.hashCode;

  User.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      email = json['email'],
      studentId = json['student_id'],
      firstName = json['firstName'],
      lastName = json['lastName'] {
    if (json['majors'] != null) {
      majors = [];
      json['majors'].forEach((v) {
        majors.add(Department.fromJson(v));
      });
    }
    if (json['departments'] != null) {
      departments = [];
      json['departments'].forEach((v) {
        departments.add(Department.fromJson(v));
      });
    }
    if (json['favorite_departments'] != null) {
      favoriteDepartments = [];
      json['favorite_departments'].forEach((v) {
        if (favoriteDepartments != null) {
          favoriteDepartments!.add(Department.fromJson(v));
        }
      });
    }
    if (json['review_writable_lectures'] != null) {
      reviewWritableLectures = [];
      json['review_writable_lectures'].forEach((v) {
        reviewWritableLectures.add(Lecture.fromJson(v));
      });
    }
    if (json['my_timetable_lectures'] != null) {
      myTimetableLectures = [];
      json['my_timetable_lectures'].forEach((v) {
        myTimetableLectures.add(Lecture.fromJson(v));
      });
    }
    if (json['reviews'] != null) {
      reviews = [];
      json['reviews'].forEach((v) {
        reviews.add(Review.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['email'] = this.email;
    data['student_id'] = this.studentId;
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    data['majors'] = this.majors.map((v) => v.toJson()).toList();
    data['departments'] = this.departments.map((v) => v.toJson()).toList();
    if (this.favoriteDepartments is List<Department>) {
      data['favorite_departments'] = this.favoriteDepartments!
          .map((v) => v.toJson())
          .toList();
    }
    data['review_writable_lectures'] = this.reviewWritableLectures
        .map((v) => v.toJson())
        .toList();
    data['my_timetable_lectures'] = this.myTimetableLectures
        .map((v) => v.toJson())
        .toList();
    data['reviews'] = this.reviews.map((v) => v.toJson()).toList();
    return data;
  }
}
