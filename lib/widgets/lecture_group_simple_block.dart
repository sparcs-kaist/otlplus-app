import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/extensions/lecture.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/theme/context_ext.dart';

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
    final isEn = EasyLocalization.of(context)?.currentLocale == Locale('en');

    return Column(
      children: <Widget>[
        if (semester == 1) const Spacer(),
        Container(
          width: isEn ? 150.0 : 100.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: ListTile.divideTiles(
              color: context.colors.textDark,
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
                    color: (lecture.professors.any(
                      (professor) =>
                          professor.professorId.toString() == filter,
                    ))
                        ? OTLColor.pinksSub // legacy: pinksSub
                        : context.colors.lineDefault,
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
                            style: context.texts.normal,
                            children: [
                              TextSpan(
                                text: lecture.classTitle,
                                style: context.texts.normalBold,
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
        if (semester == 3) const Spacer(),
      ],
    );
  }
}
