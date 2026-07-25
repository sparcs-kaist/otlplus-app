import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/pages/liked_review_page.dart';
import 'package:otlplus/pages/my_review_page.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/theme/context_ext.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/providers/info_model.dart';

class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<InfoModel>().user;
    final isEn = EasyLocalization.of(context)?.currentLocale == Locale('en');

    return OTLScaffold(
      child: OTLLayout(
        middle: Text('title.my_information'.tr(), style: context.texts.bigBold),
        body: ColoredBox(
          color: context.colors.backgroundPageDefault,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildContent(
                        context,
                        "user.name",
                        "${user.firstName} ${user.lastName}",
                      ),
                      _buildContent(context, "user.email", user.email),
                      _buildContent(context, "user.student_id", user.studentId),
                      _buildContent(
                        context,
                        "user.major",
                        user.majors
                            .map(
                              (department) =>
                                  isEn ? department.nameEn : department.name,
                            )
                            .join(", "),
                      ),
                      _buildDivider(context),
                    ],
                  ),
                ),
                _buildNavigateArrowButton(
                  context,
                  'assets/icons/my_review.svg',
                  'user.my_review'.tr(),
                  () => OTLNavigator.push(context, MyReviewPage()),
                ),
                _buildNavigateArrowButton(
                  context,
                  'assets/icons/liked_review.svg',
                  'user.liked_review'.tr(),
                  () => OTLNavigator.push(context, LikedReviewPage()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildDivider(context),
                ),
                _buildAccount(context, 'assets/icons/logout.svg', () {
                  context.read<AuthModel>().logout();
                  OTLNavigator.pop(context);
                }, 'user.logout'.tr()),
                if (Platform.isIOS)
                  _buildAccount(context, Icons.highlight_off, () {
                    OTLNavigator.pushDialog(
                      context: context,
                      builder: (_) => OTLDialog(
                        type: OTLDialogType.deleteAccount,
                        onTapPos: () {
                          context.read<AuthModel>().logout();
                          context.read<InfoModel>().deleteAccount();
                          OTLNavigator.pop(context);
                        },
                      ),
                    );
                  }, 'user.delete_account'.tr()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(color: context.colors.lineDivider);
  }

  Widget _buildContent(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(title.tr(), style: context.texts.normalBold),
          const SizedBox(width: 8.0),
          Text(body, style: context.texts.normal),
        ],
      ),
    );
  }

  Widget _buildNavigateArrowButton(
    BuildContext context,
    String icon,
    String text,
    VoidCallback onTap,
  ) {
    return RawResponsiveButton(
      data: {
        'Padding': {
          'padding': EdgeInsets.symmetric(horizontal: 16.0),
          'child': {
            'SizedBox': {
              'height': 36.0,
              'child': {
                'Row': {
                  'children': [
                    {
                      'SvgPicture.asset': {
                        'arg': icon,
                        'height': 24.0,
                        'width': 24.0,
                        'color': context.colors.highlightDefault,
                      },
                    },
                    {
                      'Padding': {
                        'padding': EdgeInsets.symmetric(horizontal: 8.0),
                        'child': {
                          'Text': {
                            'arg': text,
                            'style': context.texts.normalBold.copyWith(
                              color: context.colors.highlightDefault,
                            ),
                          },
                        },
                      },
                    },
                    {'Spacer': {}},
                    {
                      'Padding': {
                        'padding': EdgeInsets.fromLTRB(16, 6, 0, 6),
                        'child': {
                          'Icon': {
                            'arg': Icons.navigate_next,
                            'color': context.colors.highlightDefault,
                          },
                        },
                      },
                    },
                  ],
                },
              },
            },
          },
        },
      },
      onTap: onTap,
    );
  }

  Widget _buildAccount(
    BuildContext context,
    dynamic icon,
    void Function()? onTap,
    String? text,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconTextButton(
        icon: icon,
        onTap: onTap,
        text: text,
        color: context.colors.highlightDefault,
        textStyle: context.texts.normalBold,
        spaceBetween: 8.0,
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      ),
    );
  }
}
