import 'package:easy_localization/easy_localization.dart' as loc;
import 'package:flutter/material.dart';
import 'package:otlplus/theme/context_ext.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/utils/get_text_height.dart';
import 'package:otlplus/widgets/responsive_button.dart';

Color _blockColor(BuildContext context, int i) {
  final c = context.colors;
  switch (i % 16) {
    case 0:
      return c.tileTimetableRed1;
    case 1:
      return c.tileTimetableRed2;
    case 2:
      return c.tileTimetableOrange1;
    case 3:
      return c.tileTimetableOrange2;
    case 4:
      return c.tileTimetableYellow1;
    case 5:
      return c.tileTimetableYellow2;
    case 6:
      return c.tileTimetableGreen1;
    case 7:
      return c.tileTimetableGreen2;
    case 8:
      return c.tileTimetableGreen3;
    case 9:
      return c.tileTimetableBlue1;
    case 10:
      return c.tileTimetableBlue2;
    case 11:
      return c.tileTimetablePurple1;
    case 12:
      return c.tileTimetablePurple2;
    case 13:
      return c.tileTimetablePurple2;
    case 14:
      return c.tileTimetablePink1;
    default:
      return c.tileTimetablePink2;
  }
}

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
    final lineHeight = singleHeight(context, context.texts.small);
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
          style: context.texts.small.copyWith(
            color: isTemp ? context.colors.textBright : context.colors.textDark,
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
                style: context.texts.small,
                maxWidth: 54,
              ).height) ~/
          lineHeight;

      contents.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              classroomShort,
              style: context.texts.small.copyWith(
                color: isTemp
                    ? context.colors.lineDefault
                    : context.colors.textLighter,
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
            ? context.colors.highlightDefault
            : isExamTime
            ? context.colors.lineDefault
            : _blockColor(context, lecture.course),
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
