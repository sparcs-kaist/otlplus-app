import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:otlplus/theme/context_ext.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';

class PeoplePage extends StatelessWidget {
  const PeoplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OTLScaffold(
      child: OTLLayout(
        middle: Text('title.credit'.tr(), style: context.texts.bigBold),
        body: ColoredBox(
          color: context.colors.backgroundPageDefault,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildContainer(context, '2023.03 ~'),
                  ..._get202303(context),
                  const SizedBox(height: 32.0),
                  _buildContainer(context, '2020.03 ~ 2023.02'),
                  const SizedBox(height: 12.0),
                  Text(
                    'common.coming'.tr(),
                    style: context.texts.normal.copyWith(
                      color: context.colors.textDisable,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _buildContainer(BuildContext context, String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: context.colors.backgroundPageDefault,
        borderRadius: BorderRadius.circular(16.0),
      ),
      width: double.infinity,
      child: Center(child: Text(title, style: context.texts.big)),
    );
  }

  List<Widget> _get202303(BuildContext context) {
    const List<String> positions = [
      'Project Manager',
      'Tech Lead',
      'Designer',
      'Developer',
    ];

    const Map<String, dynamic> people_info = {
      'yumyum': {'name': '조유민'},
      'platypus': {'name': '오승빈'},
      'star': {'name': '문동우'},
      'lobe': {'name': '정성엽'},
      'seungho': {'name': '장승호'},
      'soongyu': {'name': '권순규'},
      'edge': {'name': '정재현'},
    };

    const List<List<String>> people = [
      ['yumyum'],
      ['platypus'],
      ['yumyum'],
      ['platypus', 'star', 'lobe', 'seungho', 'soongyu', 'edge'],
    ];

    // legacy: SPARCS brand color — not part of OTL design tokens
    const sparcsColor = Color(0xFFEBA12A);

    return List.generate(
      4,
      (i) => Column(
        children: [
          const SizedBox(height: 12.0),
          Text(positions[i], style: context.texts.smallBold),
          ...List.generate(
            people[i].length,
            (j) => Column(
              children: [
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SvgPicture.asset('assets/icons/SPARCS.svg', height: 24.0),
                    const SizedBox(width: 4),
                    Text(
                      people[i][j],
                      style: TextStyle(
                        color: sparcsColor, // legacy: SPARCS brand
                        fontSize: 15,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.15,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        people_info[people[i][j]]['name'],
                        style: TextStyle(
                          color: sparcsColor.withValues(
                            alpha: .4,
                          ), // legacy: SPARCS brand
                          fontFamily: 'NanumSquare',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.15,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
