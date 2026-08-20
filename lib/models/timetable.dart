import 'package:otlplus/models/lecture.dart';

int _requirePositive(int value, String field) {
  if (value <= 0) throw FormatException('$field must be positive');
  return value;
}

String _requireNonBlank(String value, String field) {
  if (value.trim().isEmpty) throw FormatException('$field must not be blank');
  return value;
}

int _requireSemester(int value) {
  if (value < 1 || value > 4) {
    throw FormatException('semester must be between 1 and 4');
  }
  return value;
}

int _requireNonNegative(int value, String field) {
  if (value < 0) throw FormatException('$field must not be negative');
  return value;
}

List<Lecture> _lecturesFromV2(
  Map<String, dynamic> json, {
  required int year,
  required int semester,
}) {
  final lectures = json['lectures'] as List<dynamic>;
  return lectures
      .map(
        (lecture) => Lecture.fromV2Json(
          lecture as Map<String, dynamic>,
          year: year,
          semester: semester,
        ),
      )
      .toList();
}

class TimetableListItem {
  final int id;
  final String name;
  final int year;
  final int semester;
  final int timeTableOrder;

  const TimetableListItem({
    required this.id,
    required this.name,
    required this.year,
    required this.semester,
    required this.timeTableOrder,
  });

  factory TimetableListItem.fromV2Json(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final year = json['year'] as int;
    final semester = json['semester'] as int;
    final timeTableOrder = json['timeTableOrder'] as int;

    return TimetableListItem(
      id: _requirePositive(id, 'id'),
      name: _requireNonBlank(name, 'name'),
      year: _requirePositive(year, 'year'),
      semester: _requireSemester(semester),
      timeTableOrder: _requireNonNegative(timeTableOrder, 'timeTableOrder'),
    );
  }
}

class Timetable {
  final int id;
  late List<Lecture> lectures;

  Timetable({required this.id, required this.lectures});

  factory Timetable.fromV2Detail(
    Map<String, dynamic> json, {
    required TimetableListItem summary,
  }) {
    return Timetable(
      id: summary.id,
      lectures: _lecturesFromV2(
        json,
        year: summary.year,
        semester: summary.semester,
      ),
    );
  }

  factory Timetable.fromV2MyTimetable(
    Map<String, dynamic> json, {
    required int year,
    required int semester,
  }) {
    return Timetable(
      id: -1,
      lectures: _lecturesFromV2(json, year: year, semester: semester),
    );
  }

  bool operator ==(Object other) =>
      identical(this, other) || (other is Timetable && other.id == id);

  @override
  int get hashCode => id.hashCode;

  Timetable.fromJson(Map<String, dynamic> json) : id = json['id'] {
    if (json['lectures'] != null) {
      lectures = [];
      json['lectures'].forEach((v) {
        lectures.add(Lecture.fromJson(v));
      });
    } else {
      lectures = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['lectures'] = this.lectures.map((v) => v.toJson()).toList();
    return data;
  }
}
