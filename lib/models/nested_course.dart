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
