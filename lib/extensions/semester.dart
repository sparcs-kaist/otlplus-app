import 'package:easy_localization/easy_localization.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/models/semester.dart';

extension SemesterExtension on Semester {
  String get title {
    final season = Season.fromCode(semester);
    if (season == null) return year.toString();
    return '$year ${season.labelKey.tr()}';
  }
}
