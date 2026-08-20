import 'package:otlplus/models/department.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/review.dart';

class User {
  final int id;
  final String email;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? degree;
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
    this.degree,
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

  String get displayName => "$firstName $lastName".trim();

  factory User.fromV2Json(Map<String, dynamic> json) {
    final id = _positiveInt(json["id"] as int, "User.id");
    final name = _nonEmptyString(json["name"] as String, "User.name");
    final email = _nonEmptyString(json["mail"] as String, "User.mail");
    final studentNumber = _positiveInt(
      json["studentNumber"] as int,
      "User.studentNumber",
    );
    final majors = _departmentsFromV2(json["majorDepartments"]);

    return User(
      id: id,
      email: email,
      studentId: studentNumber.toString(),
      firstName: name,
      lastName: "",
      degree: json["degree"] as String?,
      majors: majors,
      departments: List<Department>.of(majors),
      favoriteDepartments: _departmentsFromV2(json["interestedDepartments"]),
      myTimetableLectures: <Lecture>[],
      reviewWritableLectures: <Lecture>[],
      reviews: <Review>[],
    );
  }

  User.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      email = json['email'],
      studentId = json['student_id'],
      firstName = json['firstName'],
      lastName = json['lastName'],
      degree = null {
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

List<Department> _departmentsFromV2(Object? value) {
  return (value as List<dynamic>)
      .map(
        (department) =>
            Department.fromV2Json(department as Map<String, dynamic>),
      )
      .toList(growable: false);
}

int _positiveInt(int value, String field) {
  if (value <= 0) {
    throw FormatException("$field must be a positive integer");
  }
  return value;
}

String _nonEmptyString(String value, String field) {
  if (value.trim().isEmpty) {
    throw FormatException("$field must be a non-empty string");
  }
  return value;
}
