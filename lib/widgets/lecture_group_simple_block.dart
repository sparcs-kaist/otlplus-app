import 'package:flutter/material.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/extensions/lecture.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/extensions/locale.dart';

class LectureGroupSimpleBlock extends StatelessWidget {
  final List<Lecture> lectures;
  final int semester;
  final String? filter;

  LectureGroupSimpleBlock({
    required this.lectures,
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
              tiles: lectures.map(
                (lecture) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: (lectures.first == lecture)
                          ? const Radius.circular(4.0)
                          : Radius.zero,
                      bottom: (lectures.last == lecture)
                          ? const Radius.circular(4.0)
                          : Radius.zero,
                    ),
                    color:
                        (lecture.professors.any(
                          (professor) =>
                              professor.professorId.toString() == filter,
                        ))
                        ? OTLColor.pinksSub
                        : OTLColor.grayE,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: (lectures.first == lecture)
                          ? const Radius.circular(4.0)
                          : Radius.zero,
                      bottom: (lectures.last == lecture)
                          ? const Radius.circular(4.0)
                          : Radius.zero,
                    ),
                    child: BackgroundButton(
                      onTap: () {
                        context.read<LectureDetailModel>().loadLecture(
                          lecture.id,
                          false,
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
                                text: lecture.classTitle,
                                style: bodyBold,
                              ),
                              TextSpan(text: ' '),
                              TextSpan(
                                text: isEn
                                    ? lecture.professorsStrShortEn
                                    : lecture.professorsStrShort,
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
