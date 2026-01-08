import 'package:otlplus/models/course.dart';
import 'package:otlplus/models/professor.dart';

final scores = [
  "?",
  "F",
  "F",
  "F",
  "D-",
  "D",
  "D+",
  "C-",
  "C",
  "C+",
  "B-",
  "B",
  "B+",
  "A-",
  "A",
  "A+",
];

extension CourseExtension on Course {
  String get gradeLetter =>
      (reviewTotalWeight == 0) ? "?" : scores[grade.round()];
  String get loadLetter =>
      (reviewTotalWeight == 0) ? "?" : scores[load.round()];
  String get speechLetter =>
      (reviewTotalWeight == 0) ? "?" : scores[speech.round()];
  String get professorsStr {
    final professors = List<Professor>.from(this.professors)
      ..sort((a, b) => a.name.compareTo(b.name));
    return professors.map((professor) => professor.name).join(", ");
  }

  String get professorsStrEn {
    final professors = List<Professor>.from(this.professors)
      ..sort((a, b) => a.name.compareTo(b.name));
    return professors
        .map(
          (professor) =>
              (professor.nameEn == '' ? professor.name : professor.nameEn),
        )
        .join(", ");
  }
}
