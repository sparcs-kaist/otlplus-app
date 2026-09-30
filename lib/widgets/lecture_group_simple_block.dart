import 'package:flutter/material.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/extensions/locale.dart';

class LectureGroupSimpleBlock extends StatelessWidget {
  final Course course;
  final CourseHistory history;
  final int semester;
  final String? filter;

  LectureGroupSimpleBlock({
    required this.course,
    required this.history,
    required this.semester,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final isEn = context.isEn;
    final season = Season.fromCode(semester);
    final isBeforeYear = season == Season.spring || season == Season.summer;
    final isAfterYear = season == Season.fall || season == Season.winter;

    return Column(
      children: <Widget>[
        if (isBeforeYear) const Spacer(),
        Container(
          width: isEn ? 150.0 : 100.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: ListTile.divideTiles(
              color: OTLColor.gray0,
              tiles: history.classes.map(
                (entry) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: (history.classes.first == entry)
                          ? const Radius.circular(4.0)
                          : Radius.zero,
                      bottom: (history.classes.last == entry)
                          ? const Radius.circular(4.0)
                          : Radius.zero,
                    ),
                    color:
                        (entry.professors.any(
                          (professor) =>
                              professor.professorId.toString() == filter,
                        ))
                        ? OTLColor.pinksSub
                        : OTLColor.grayE,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: (history.classes.first == entry)
                          ? const Radius.circular(4.0)
                          : Radius.zero,
                      bottom: (history.classes.last == entry)
                          ? const Radius.circular(4.0)
                          : Radius.zero,
                    ),
                    child: BackgroundButton(
                      onTap: () {
                        context.read<LectureDetailModel>().loadHistoryLecture(
                          course,
                          history,
                          entry,
                        );
                        OTLNavigator.push(
                          context,
                          LectureDetailPage(fromCourseDetailPage: true),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Text.rich(
                          TextSpan(
                            style: bodyRegular,
                            children: [
                              TextSpan(
                                text: [
                                  entry.classNo,
                                  entry.subtitle,
                                ].where((value) => value.isNotEmpty).join(' '),
                                style: bodyBold,
                              ),
                              TextSpan(text: ' '),
                              TextSpan(
                                text: isEn
                                    ? entry.professors
                                          .map(
                                            (p) => p.nameEn.isEmpty
                                                ? p.name
                                                : p.nameEn,
                                          )
                                          .join(", ")
                                    : entry.professors
                                          .map((p) => p.name)
                                          .join(", "),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
        if (isAfterYear) const Spacer(),
      ],
    );
  }
}
