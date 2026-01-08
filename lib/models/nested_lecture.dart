import 'package:otlplus/models/professor.dart';

class NestedLecture {
  final int id;
  final String title;
  final String titleEn;
  final int course;
  final String oldCode;
  final String classNo;
  final int year;
  final int semester;
  final String code;
  final int department;
  final String departmentCode;
  final String departmentName;
  final String departmentNameEn;
  final String type;
  final String typeEn;
  final int limit;
  final int numPeople;
  final bool isEnglish;
  final int credit;
  final int creditAu;
  final String commonTitle;
  final String commonTitleEn;
  final String classTitle;
  final String classTitleEn;
  final double reviewTotalWeight;
  late List<Professor> professors;

  NestedLecture({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.course,
    required this.oldCode,
    required this.classNo,
    required this.year,
    required this.semester,
    required this.code,
    required this.department,
    required this.departmentCode,
    required this.departmentName,
    required this.departmentNameEn,
    required this.type,
    required this.typeEn,
    required this.limit,
    required this.numPeople,
    required this.isEnglish,
    required this.credit,
    required this.creditAu,
    required this.commonTitle,
    required this.commonTitleEn,
    required this.classTitle,
    required this.classTitleEn,
    required this.reviewTotalWeight,
    required this.professors,
  });

  bool operator ==(Object other) =>
      identical(this, other) || (other is NestedLecture && other.id == id);

  int get hashCode => id.hashCode;

  NestedLecture.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      title = json['title'],
      titleEn = json['title_en'],
      course = json['course'],
      oldCode = json['old_code'],
      classNo = json['class_no'],
      year = json['year'],
      semester = json['semester'],
      code = json['code'],
      department = json['department'],
      departmentCode = json['department_code'],
      departmentName = json['department_name'],
      departmentNameEn = json['department_name_en'],
      type = json['type'],
      typeEn = json['type_en'],
      limit = json['limit'],
      numPeople = json['num_people'],
      isEnglish = json['is_english'],
      credit = json['credit'],
      creditAu = json['credit_au'],
      commonTitle = json['common_title'],
      commonTitleEn = json['common_title_en'],
      classTitle = json['class_title'],
      classTitleEn = json['class_title_en'],
      reviewTotalWeight = json['review_total_weight'] {
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
    data['title'] = this.title;
    data['title_en'] = this.titleEn;
    data['course'] = this.course;
    data['old_code'] = this.oldCode;
    data['class_no'] = this.classNo;
    data['year'] = this.year;
    data['semester'] = this.semester;
    data['code'] = this.code;
    data['department'] = this.department;
    data['department_code'] = this.departmentCode;
    data['department_name'] = this.departmentName;
    data['department_name_en'] = this.departmentNameEn;
    data['type'] = this.type;
    data['type_en'] = this.typeEn;
    data['limit'] = this.limit;
    data['num_people'] = this.numPeople;
    data['is_english'] = this.isEnglish;
    data['credit'] = this.credit;
    data['credit_au'] = this.creditAu;
    data['common_title'] = this.commonTitle;
    data['common_title_en'] = this.commonTitleEn;
    data['class_title'] = this.classTitle;
    data['class_title_en'] = this.classTitleEn;
    data['review_total_weight'] = this.reviewTotalWeight;
    data['professors'] = this.professors.map((v) => v.toJson()).toList();
    return data;
  }
}
