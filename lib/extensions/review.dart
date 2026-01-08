import 'package:otlplus/models/review.dart';

final scores = ["?", "F", "D", "C", "B", "A"];

extension ReviewExtension on Review {
  String get gradeLetter => scores[grade];
  String get loadLetter => scores[load];
  String get speechLetter => scores[speech];
}
