import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/theme/context_ext.dart';
import 'package:otlplus/extensions/course.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/widgets/responsive_button.dart';

class CourseBlock extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  CourseBlock({required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEn = EasyLocalization.of(context)?.currentLocale == Locale('en');

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: BackgroundButton(
        color: context.colors.lineDefault,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: isEn ? course.titleEn : course.title,
                      style: context.texts.normalBold,
                    ),
                    const TextSpan(text: " "),
                    TextSpan(text: course.oldCode, style: context.texts.normal),
                  ],
                ),
              ),
              _buildDivider(context),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("dictionary.type".tr(), style: context.texts.smallBold),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      "${isEn ? course.department?.nameEn : course.department?.name}, ${isEn ? course.typeEn : course.type}",
                      style: context.texts.small,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "dictionary.professors".tr(),
                    style: context.texts.smallBold,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      isEn ? course.professorsStrEn : course.professorsStr,
                      style: context.texts.small,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "dictionary.description".tr(),
                    style: context.texts.smallBold,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(course.summary, style: context.texts.small),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(color: context.colors.textDark.withValues(alpha: .25));
  }
}
