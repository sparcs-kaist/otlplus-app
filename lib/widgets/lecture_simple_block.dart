import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/theme/context_ext.dart';

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
    final isEn = EasyLocalization.of(context)?.currentLocale == Locale('en');

    return Container(
      margin: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: context.colors.lineDefault,
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
                  style: context.texts.normal.copyWith(
                    color: hasReview
                        ? context.colors.textDark.withValues(alpha: .4)
                        : context.colors.textDark,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: isEn ? lecture.titleEn : lecture.title,
                      style: context.texts.normalBold,
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
