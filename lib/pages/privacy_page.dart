import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/privacy.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OTLScaffold(
      child: OTLLayout(
        middle: Text('title.privacy'.tr(), style: titleBold),
        body: ColoredBox(
          color: OTLColor.grayF,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text.rich(
                  TextSpan(
                    style: bodyRegular,
                    children: <TextSpan>[
                      TextSpan(
                        text: privacyText0,
                        children: List.generate(
                          12,
                          (index) => TextSpan(
                            children: [
                              TextSpan(text: '\n'),
                              TextSpan(
                                text: privacyTitles[index],
                                style: bodyBold,
                              ),
                              TextSpan(text: '\n'),
                              TextSpan(text: privacyTexts[index]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
