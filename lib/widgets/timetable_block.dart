import 'package:easy_localization/easy_localization.dart' as loc;
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/utils/get_text_height.dart';
import 'package:otlplus/widgets/responsive_button.dart';

class TimetableBlock extends StatelessWidget {
  final Lecture lecture;
  final int classTimeIndex;
  final double height;
  final double fontSize;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isTemp;
  final bool isExamTime;
  final bool showTitle;
  final bool showClassroom;

  TimetableBlock({
    Key? key,
    required this.lecture,
    this.classTimeIndex = 0,
    this.height = 78,
    this.fontSize = 9.0,
    this.onTap,
    this.onLongPress,
    this.isTemp = false,
    this.isExamTime = false,
    this.showTitle = true,
    this.showClassroom = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isKo = context.locale == Locale('ko');
    final title = isKo ? lecture.title : lecture.titleEn;
    final classroomShort = isKo
        ? lecture.classtimes[classTimeIndex].classroomShort
        : lecture.classtimes[classTimeIndex].classroomShortEn;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2.0),
      child: BackgroundButton(
        color: isTemp
            ? OTLColor.pinksMain
            : isExamTime
            ? OTLColor.grayE
            : OTLColor.blockColors[lecture.course % 16],
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final titleHeight = showTitle
                  ? getTextSize(
                      context,
                      text: title,
                      style: labelRegular,
                      maxWidth: constraints.maxWidth,
                      maxLines: 2,
                    ).height
                  : 0.0;

              final classRoomLineHeight = singleHeight(
                context,
                labelRegular.copyWith(fontSize: 10),
              );
              int classRoomMaxLines =
                  ((constraints.maxHeight - titleHeight - 4) ~/
                  classRoomLineHeight);

              if (classRoomMaxLines < 1) classRoomMaxLines = 1;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTitle)
                    Text(
                      title,
                      style: labelRegular.copyWith(
                        color: isTemp ? OTLColor.grayF : OTLColor.gray0,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 2,
                    ),
                  if (showClassroom)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          classroomShort,
                          style: labelRegular.copyWith(
                            color: isTemp ? OTLColor.grayE : OTLColor.gray6,
                            overflow: TextOverflow.ellipsis,
                            fontSize: 10,
                          ),
                          maxLines: classRoomMaxLines,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
