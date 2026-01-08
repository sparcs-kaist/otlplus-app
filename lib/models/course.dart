import 'package:otlplus/models/department.dart';
import 'package:otlplus/models/professor.dart';

class Course {
  final int id;
  final String oldCode;
  final Department? department;
  final String type;
  final String typeEn;
  final String title;
  final String titleEn;
  final String summary;
  final double reviewTotalWeight;
  late List<Professor> professors;
  final double grade;
  final double load;
  final double speech;
  final bool userspecificIsRead;

  Course({
    required this.id,
    required this.oldCode,
    this.department,
    required this.type,
    required this.typeEn,
    required this.title,
    required this.titleEn,
    required this.summary,
    required this.reviewTotalWeight,
    required this.professors,
    required this.grade,
    required this.load,
    required this.speech,
    required this.userspecificIsRead,
  });

  bool operator ==(Object other) =>
      identical(this, other) || (other is Course && other.id == id);

  int get hashCode => id.hashCode;

  Course.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      oldCode = json['old_code'],
      department = Department.fromJson(json['department']),
      type = json['type'],
      typeEn = json['type_en'],
      title = json['title'],
      titleEn = json['title_en'],
      summary = json['summary'],
      reviewTotalWeight = json['review_total_weight'],
      grade = json['grade']?.toDouble(),
      load = json['load']?.toDouble(),
      speech = json['speech']?.toDouble(),
      userspecificIsRead = json['userspecific_is_read'] {
    if (json['professors'] != null) {
      professors = [];
      json['professors'].forEach((v) {
        professors.add(Professor.fromJson(v));
      });
    }
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
    data['professors'] = this.professors.map((v) => v.toJson()).toList();
    data['grade'] = this.grade;
    data['load'] = this.load;
    data['speech'] = this.speech;
    data['userspecific_is_read'] = this.userspecificIsRead;
    return data;
  }
}
