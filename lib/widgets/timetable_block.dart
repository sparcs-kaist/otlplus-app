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
    final contents = <Widget>[];
    final validHeight = height - 16;
    final lineHeight = singleHeight(context, labelRegular);
    int maxLines = (validHeight - lineHeight) ~/ lineHeight;
    final isKo = context.locale == Locale('ko');
    final title = isKo ? lecture.title : lecture.titleEn;
    final classroomShort = isKo
        ? lecture.classtimes[classTimeIndex].classroomShort
        : lecture.classtimes[classTimeIndex].classroomShortEn;

    if (showTitle) {
      contents.add(
        Text(
          title,
          style: labelRegular.copyWith(
            color: isTemp ? OTLColor.grayF : OTLColor.gray0,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 2,
        ),
      );
    }

    if (showClassroom) {
      maxLines =
          (validHeight -
              getTextSize(
                context,
                text: title,
                style: labelRegular,
                maxWidth: 54,
              ).height) ~/
          lineHeight;

      contents.add(
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
              maxLines: maxLines > 1 ? maxLines : 1,
            ),
          ),
        ),
      );
    }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: contents,
          ),
        ),
      ),
    );
  }
}
