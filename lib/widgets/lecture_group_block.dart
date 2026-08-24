import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/widgets/lecture_group_block_row.dart';
import 'package:otlplus/extensions/locale.dart';

class LectureGroupBlock extends StatelessWidget {
  final List<Lecture> lectures;
  final void Function(Lecture) onLongPress;

  LectureGroupBlock({required this.lectures, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final isEn = context.isEn;

    if (lectures.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6.0),
        padding: const EdgeInsets.only(top: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          color: OTLColor.grayE,
        ),
        child: Text("There is no lecture."),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        color: OTLColor.grayE,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 4.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isEn
                          ? lectures.first.commonTitleEn
                          : lectures.first.commonTitle,
                      style: bodyBold,
                    ),
                    const SizedBox(width: 4),
                    Text(lectures.first.oldCode, style: bodyRegular),
                  ],
                ),
                Text.rich(
                  TextSpan(
                    style: labelRegular.copyWith(color: OTLColor.grayA),
                    children: <TextSpan>[
                      TextSpan(text: lectures.first.departmentCode),
                      const TextSpan(text: " / "),
                      TextSpan(
                        text: isEn
                            ? lectures.first.typeEn
                            : lectures.first.type,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: OTLColor.grayA),
            ),
          ),
          ...lectures.map(
            (lecture) => LectureGroupBlockRow(
              lecture: lecture,
              onLongPress: () => onLongPress(lecture),
            ),
          ),
        ],
      ),
    );
  }
}
