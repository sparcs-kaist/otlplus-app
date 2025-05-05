import 'package:otlplus/models/lecture.dart';

class Timetable {
  final int id;
  late List<Lecture> lectures;

  Timetable({
    required this.id,
    required this.lectures,
  });

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
