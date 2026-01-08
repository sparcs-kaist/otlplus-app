import 'package:otlplus/models/classtime.dart';
import 'package:otlplus/models/examtime.dart';
import 'package:otlplus/models/professor.dart';

const TYPES = [
  "Basic Required",
  "Basic Elective",
  "Major Required",
  "Major Elective",
  "Humanities & Social Elective",
];

int _indexOfType(String type) {
  final int idx = TYPES.indexWhere((tp) => type.startsWith(tp));
  return idx == -1 ? 5 : idx; //ETC == 5
}

class Lecture {
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
  final int typeIdx;
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
  final double grade;
  final double load;
  final double speech;
  late List<Classtime> classtimes;
  late List<Examtime> examtimes;

  Lecture({
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
    required this.typeIdx,
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
    required this.grade,
    required this.load,
    required this.speech,
    required this.classtimes,
    required this.examtimes,
  });

  bool operator ==(Object other) =>
      identical(this, other) || (other is Lecture && other.id == id);

  int get hashCode => id.hashCode;

  Lecture.fromJson(Map<String, dynamic> json)
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
      typeIdx = _indexOfType(json['type_en']),
      limit = json['limit'],
      numPeople = json['num_people'],
      isEnglish = json['is_english'],
      credit = json['credit'],
      creditAu = json['credit_au'],
      commonTitle = json['common_title'],
      commonTitleEn = json['common_title_en'],
      classTitle = json['class_title'],
      classTitleEn = json['class_title_en'],
      reviewTotalWeight = json['review_total_weight'],
      grade = json['grade']?.toDouble(),
      load = json['load']?.toDouble(),
      speech = json['speech']?.toDouble() {
    if (json['professors'] != null) {
      professors = [];
      json['professors'].forEach((v) {
        professors.add(Professor.fromJson(v));
      });
    }

    if (json['classtimes'] != null) {
      classtimes = [];
      json['classtimes'].forEach((v) {
        classtimes.add(Classtime.fromJson(v));
      });
    }
    if (json['examtimes'] != null) {
      examtimes = [];
      json['examtimes'].forEach((v) {
        examtimes.add(Examtime.fromJson(v));
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
    data['type_idx'] = this.typeIdx;
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
    data['grade'] = this.grade;
    data['load'] = this.load;
    data['speech'] = this.speech;
    data['classtimes'] = this.classtimes.map((v) => v.toJson()).toList();
    data['examtimes'] = this.examtimes.map((v) => v.toJson()).toList();
    return data;
  }
}
