import 'package:otlplus/models/lecture.dart';

class Timetable {
  final int id;
  final int year;
  final int semester;
  late List<Lecture> lectures;

  Timetable({
    required this.id,
    required this.year,
    required this.semester,
    required this.lectures,
  });

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Timetable &&
          other.id == id &&
          other.year == year &&
          other.semester == semester);

  @override
  int get hashCode => id.hashCode ^ year.hashCode ^ semester.hashCode;

  Timetable.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        year = json['year'],
        semester = json['semester'] {
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
    data['year'] = this.year;
    data['semester'] = this.semester;
    data['lectures'] = this.lectures.map((v) => v.toJson()).toList();
    return data;
  }
}
