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

  /// Parses a v2 review Basic lecture shape and any optional richer fields.
  factory NestedLecture.fromV2Json(Map<String, dynamic> json) {
    final lectureId = _nestedLectureRequiredInt(
      json['lectureId'] ?? json['id'],
      'NestedLecture.lectureId',
    );
    final courseId = _nestedLectureRequiredInt(
      json['courseId'] ?? json['course'],
      'NestedLecture.courseId',
    );
    final courseName = _nestedLectureRequiredString(
      json['courseName'] ?? json['name'] ?? json['title'],
      'NestedLecture.courseName',
    );
    final professors = json['professors'] is List
        ? (json['professors'] as List)
              .whereType<Map>()
              .map(
                (value) => Professor.fromV2Json(
                  Map<String, dynamic>.from(value),
                ),
              )
              .toList(growable: false)
        : const <Professor>[];
    final departmentJson = json['department'];
    final departmentMap = departmentJson is Map
        ? Map<String, dynamic>.from(departmentJson)
        : const <String, dynamic>{};
    final departmentId = departmentJson is int
        ? departmentJson
        : _nestedLectureInt(departmentMap['id']);
    final departmentName = _nestedLectureString(
      json['departmentName'] ?? departmentMap['name'],
    );
    final type = _nestedLectureString(json['type']);
    final code = _nestedLectureString(json['code']);

    return NestedLecture(
      id: lectureId,
      title: courseName,
      titleEn: _nestedLectureString(json['courseNameEn'], fallback: courseName),
      course: courseId,
      oldCode: _nestedLectureString(json['oldCode'] ?? code),
      classNo: _nestedLectureString(json['classNo']),
      year: _nestedLectureRequiredInt(json['year'], 'NestedLecture.year'),
      semester: _nestedLectureRequiredInt(
        json['semester'],
        'NestedLecture.semester',
      ),
      code: code,
      department: departmentId,
      departmentCode: _nestedLectureString(
        json['departmentCode'] ?? departmentMap['code'],
      ),
      departmentName: departmentName,
      departmentNameEn: _nestedLectureString(
        json['departmentNameEn'] ?? departmentMap['nameEn'],
        fallback: departmentName,
      ),
      type: type,
      typeEn: _nestedLectureString(json['typeEn'], fallback: type),
      limit: _nestedLectureInt(json['limitPeople'] ?? json['limit']),
      numPeople: _nestedLectureInt(json['numPeople']),
      isEnglish: _nestedLectureBool(json['isEnglish']),
      credit: _nestedLectureInt(json['credit']),
      creditAu: _nestedLectureInt(json['creditAU'] ?? json['creditAu']),
      commonTitle: courseName,
      commonTitleEn: _nestedLectureString(
        json['courseNameEn'],
        fallback: courseName,
      ),
      classTitle: _nestedLectureString(json['subtitle']),
      classTitleEn: _nestedLectureString(
        json['subtitleEn'],
        fallback: _nestedLectureString(json['subtitle']),
      ),
      reviewTotalWeight: _nestedLectureDouble(json['reviewTotalWeight']),
      professors: professors,
    );
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

String _nestedLectureRequiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

int _nestedLectureRequiredInt(Object? value, String field) {
  if (value is! int || value <= 0) {
    throw FormatException('$field must be a positive integer');
  }
  return value;
}

String _nestedLectureString(Object? value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value : fallback;
}

int _nestedLectureInt(Object? value) => value is num ? value.toInt() : 0;

bool _nestedLectureBool(Object? value) => value is bool ? value : false;

double _nestedLectureDouble(Object? value) => value is num ? value.toDouble() : 0;
