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
  final bool open;
  final bool completed;
  final int classDuration;
  final int expDuration;
  final double credit;
  final double creditAU;
  final List<CourseHistory> history;

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
    this.open = false,
    this.completed = false,
    this.classDuration = 0,
    this.expDuration = 0,
    this.credit = 0,
    this.creditAU = 0,
    this.history = const <CourseHistory>[],
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
      userspecificIsRead = json['userspecific_is_read'],
      open = false,
      completed = false,
      classDuration = 0,
      expDuration = 0,
      credit = 0,
      creditAU = 0,
      history = const <CourseHistory>[] {
    if (json['professors'] != null) {
      professors = [];
      json['professors'].forEach((v) {
        professors.add(Professor.fromJson(v));
      });
    }
  }

  factory Course.fromV2Json(Map<String, dynamic> json) {
    final history = _v2List(
      json['history'],
    ).map(CourseHistory.fromV2Json).toList(growable: false);
    final professorById = <int, Professor>{};

    for (final professorJson in _v2List(json['professors'])) {
      final professor = _professorFromV2Json(professorJson);
      if (professor != null) {
        professorById[professor.professorId] = professor;
      }
    }
    for (final entry in history) {
      for (final courseClass in entry.classes) {
        for (final professor in courseClass.professors) {
          professorById.putIfAbsent(professor.professorId, () => professor);
        }
      }
    }

    final name = _v2RequiredString(json['name'], 'Course.name');
    final type = _v2RequiredString(json['type'], 'Course.type');

    return Course(
      id: _v2RequiredInt(json['id'], 'Course.id'),
      oldCode: _v2RequiredString(json['code'], 'Course.code'),
      department: _departmentFromV2Json(json['department']),
      type: type,
      typeEn: type,
      title: name,
      titleEn: name,
      summary: _v2String(json['summary']),
      reviewTotalWeight: 0,
      professors: professorById.values.toList(growable: false),
      grade: 0,
      load: 0,
      speech: 0,
      userspecificIsRead: false,
      open: _v2Bool(json['open']),
      completed: _v2Bool(json['completed']),
      classDuration: _v2Int(json['classDuration']),
      expDuration: _v2Int(json['expDuration']),
      credit: _v2Double(json['credit']),
      creditAU: _v2Double(json['creditAU']),
      history: history,
    );
  }

  Course withReviewAverages({
    required double grade,
    required double load,
    required double speech,
  }) {
    return Course(
      id: id,
      oldCode: oldCode,
      department: department,
      type: type,
      typeEn: typeEn,
      title: title,
      titleEn: titleEn,
      summary: summary,
      reviewTotalWeight: reviewTotalWeight,
      professors: professors,
      grade: grade,
      load: load,
      speech: speech,
      userspecificIsRead: userspecificIsRead,
      open: open,
      completed: completed,
      classDuration: classDuration,
      expDuration: expDuration,
      credit: credit,
      creditAU: creditAU,
      history: history,
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
    data['professors'] = this.professors.map((v) => v.toJson()).toList();
    data['grade'] = this.grade;
    data['load'] = this.load;
    data['speech'] = this.speech;
    data['userspecific_is_read'] = this.userspecificIsRead;
    return data;
  }
}

class CourseHistory {
  const CourseHistory({
    required this.year,
    required this.semester,
    required this.classes,
    required this.myLectureId,
  });

  final int year;
  final int semester;
  final List<CourseHistoryClass> classes;
  final int? myLectureId;

  factory CourseHistory.fromV2Json(Map<String, dynamic> json) {
    return CourseHistory(
      year: _v2RequiredInt(json['year'], 'CourseHistory.year'),
      semester: _v2RequiredInt(json['semester'], 'CourseHistory.semester'),
      classes: _v2List(
        json['classes'],
      ).map(CourseHistoryClass.fromV2Json).toList(growable: false),
      myLectureId: _v2NullableInt(json['myLectureId']),
    );
  }
}

class CourseHistoryClass {
  const CourseHistoryClass({
    required this.professors,
    required this.classNo,
    required this.lectureId,
    required this.subtitle,
  });

  final List<Professor> professors;
  final String classNo;
  final int lectureId;
  final String subtitle;

  factory CourseHistoryClass.fromV2Json(Map<String, dynamic> json) {
    return CourseHistoryClass(
      professors: _v2List(json['professors'])
          .map(_professorFromV2Json)
          .whereType<Professor>()
          .toList(growable: false),
      classNo: _v2String(json['classNo']),
      lectureId: _v2RequiredInt(
        json['lectureId'],
        'CourseHistoryClass.lectureId',
      ),
      subtitle: _v2String(json['subtitle']),
    );
  }
}

Department? _departmentFromV2Json(Object? value) {
  if (value is! Map) return null;
  final json = Map<String, dynamic>.from(value);
  final id = _v2NullableInt(json['id']);
  if (id == null) return null;

  final name = _v2String(json['name']);
  return Department(
    id: id,
    name: name,
    nameEn: name,
    code: _v2String(json['code']),
  );
}

Professor? _professorFromV2Json(Map<String, dynamic> json) {
  final id = _v2NullableInt(json['id']);
  if (id == null) return null;

  final name = _v2String(json['name']);
  return Professor(
    name: name,
    nameEn: name,
    professorId: id,
    reviewTotalWeight: 0,
  );
}

List<Map<String, dynamic>> _v2List(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
}

String _v2RequiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

int _v2RequiredInt(Object? value, String field) {
  if (value is! int || value <= 0) {
    throw FormatException('$field must be a positive integer');
  }
  return value;
}

String _v2String(Object? value) => value is String ? value : '';

int _v2Int(Object? value) => value is num ? value.toInt() : 0;

int? _v2NullableInt(Object? value) => value is num ? value.toInt() : null;

double _v2Double(Object? value) => value is num ? value.toDouble() : 0;

bool _v2Bool(Object? value) => value is bool ? value : false;
