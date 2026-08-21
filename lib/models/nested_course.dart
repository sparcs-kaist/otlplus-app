import 'package:otlplus/models/department.dart';

class NestedCourse {
  final int id;
  final String oldCode;
  final Department? department;
  final String type;
  final String typeEn;
  final String title;
  final String titleEn;
  final String summary;
  final double reviewTotalWeight;

  NestedCourse({
    required this.id,
    required this.oldCode,
    this.department,
    required this.type,
    required this.typeEn,
    required this.title,
    required this.titleEn,
    required this.summary,
    required this.reviewTotalWeight,
  });

  bool operator ==(Object other) =>
      identical(this, other) || (other is NestedCourse && other.id == id);

  int get hashCode => id.hashCode;

  NestedCourse.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      oldCode = json['old_code'],
      department = Department.fromJson(json['department']),
      type = json['type'],
      typeEn = json['type_en'],
      title = json['title'],
      titleEn = json['title_en'],
      summary = json['summary'],
      reviewTotalWeight = json['review_total_weight'];

  /// Parses a v2 course Basic/review nested shape.
  factory NestedCourse.fromV2Json(Map<String, dynamic> json) {
    final id = _nestedCourseRequiredInt(
      json['id'] ?? json['courseId'],
      'NestedCourse.id',
    );
    final name = _nestedCourseRequiredString(
      json['name'] ?? json['courseName'],
      'NestedCourse.name',
    );
    final departmentJson = json['department'];
    final type = _nestedCourseString(json['type']);
    return NestedCourse(
      id: id,
      oldCode: _nestedCourseString(json['code'] ?? json['oldCode']),
      department: departmentJson is Map
          ? Department.fromV2Json(Map<String, dynamic>.from(departmentJson))
          : null,
      type: type,
      typeEn: _nestedCourseNullableString(json['typeEn']) ?? type,
      title: name,
      titleEn: _nestedCourseNullableString(json['nameEn']) ?? name,
      summary: _nestedCourseString(json['summary']),
      reviewTotalWeight: _nestedCourseDouble(json['reviewTotalWeight']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['old_code'] = this.oldCode;
    if (this.department != null) {
      data['department'] = this.department!.toJson();
    }
    data['type'] = this.type;
    data['type_en'] = this.typeEn;
    data['title'] = this.title;
    data['title_en'] = this.titleEn;
    data['summary'] = this.summary;
    data['review_total_weight'] = this.reviewTotalWeight;
    return data;
  }
}

String _nestedCourseRequiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

int _nestedCourseRequiredInt(Object? value, String field) {
  if (value is! int || value <= 0) {
    throw FormatException('$field must be a positive integer');
  }
  return value;
}

String _nestedCourseString(Object? value) => value is String ? value : '';

String? _nestedCourseNullableString(Object? value) {
  return value is String && value.trim().isNotEmpty ? value : null;
}

double _nestedCourseDouble(Object? value) =>
    value is num ? value.toDouble() : 0;
