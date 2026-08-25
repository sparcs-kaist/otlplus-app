import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/extensions/course.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/extensions/locale.dart';

class CourseBlock extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  CourseBlock({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEn = context.isEn;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: BackgroundButton(
        color: OTLColor.grayE,
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
                      style: bodyBold,
                    ),
                    const TextSpan(text: " "),
                    TextSpan(text: course.oldCode, style: bodyRegular),
                  ],
                ),
              ),
              _buildDivider(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("dictionary.type".tr(), style: labelBold),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      "${isEn ? course.department?.nameEn : course.department?.name}, ${isEn ? course.typeEn : course.type}",
                      style: labelRegular,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("dictionary.professors".tr(), style: labelBold),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      isEn ? course.professorsStrEn : course.professorsStr,
                      style: labelRegular,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("dictionary.description".tr(), style: labelBold),
                  const SizedBox(width: 8.0),
                  Expanded(child: Text(course.summary, style: labelRegular)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: OTLColor.divider);
  }
}
