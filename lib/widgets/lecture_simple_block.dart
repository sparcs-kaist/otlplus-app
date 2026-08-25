import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/extensions/locale.dart';

class LectureSimpleBlock extends StatelessWidget {
  final Lecture lecture;
  final bool hasReview;
  final VoidCallback? onTap;

  LectureSimpleBlock({
    required this.lecture,
    this.hasReview = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEn = context.isEn;

    return Container(
      margin: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: OTLColor.grayE,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: BackgroundButton(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 8.0,
            ),
            child: Center(
              child: Text.rich(
                TextSpan(
                  style: bodyRegular.copyWith(
                    color: hasReview
                        ? OTLColor.disabledOverlay
                        : OTLColor.gray0,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: isEn ? lecture.titleEn : lecture.title,
                      style: bodyBold,
                    ),
                    const TextSpan(text: "\n"),
                    TextSpan(text: lecture.oldCode),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
