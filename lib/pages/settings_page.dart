import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/widgets/dropdown.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:easy_localization/easy_localization.dart';
import 'package:channel_talk_flutter/channel_talk_flutter.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isEn = EasyLocalization.of(context)?.currentLocale == Locale('en');

    return OTLScaffold(
      child: OTLLayout(
        middle: Text('title.settings'.tr(), style: titleBold),
        body: ColoredBox(
          color: OTLColor.grayF,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "settings.language".tr(),
                      style: bodyBold,
                    ),
                    Dropdown<bool>(
                      customButton: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: OTLColor.pinksLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.language,
                              color: OTLColor.pinksMain,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEn
                                  ? "settings.english".tr()
                                  : "settings.korean".tr(),
                              style: bodyBold.copyWith(
                                  height: 1.2, color: OTLColor.pinksMain),
                            )
                          ],
                        ),
                      ),
                      items: [
                        ItemData(
                          value: false,
                          text: "settings.korean".tr(),
                          icon: !isEn ? Icons.check : null,
                        ),
                        ItemData(
                          value: true,
                          text: "settings.english".tr(),
                          icon: isEn ? Icons.check : null,
                        ),
                      ],
                      isIconLeft: true,
                      offsetY: -6,
                      onChanged: (value) {
                        if (value!) {
                          EasyLocalization.of(context)?.setLocale(Locale('en'));
                        } else {
                          EasyLocalization.of(context)?.setLocale(Locale('ko'));
                        }
                      },
                    ),
                  ],
                ),
                _buildListTile(
                  title: "settings.receive_promotion".tr(),
                  subtitle: "settings.receive_promotion_desc".tr(),
                  trailing: CupertinoSwitch(
                    value: context.watch<SettingsModel>().getReceivePromotion(),
                    onChanged: (value) {
                      context.read<SettingsModel>().setReceivePromotion(value);
                      OTLNavigator.pushDialog(
                        context: context,
                        builder: (_) => OTLDialog(
                          type: value
                              ? OTLDialogType.enablePromotion
                              : OTLDialogType.disablePromotion,
                        ),
                      );
                    },
                  ),
                ),
                _buildListTile(
                  title: "settings.send_error_log".tr(),
                  subtitle: "settings.send_error_log_desc".tr(),
                  trailing: CupertinoSwitch(
                    value: context.watch<SettingsModel>().getSendCrashlytics(),
                    onChanged: (value) =>
                        context.read<SettingsModel>().setSendCrashlytics(value),
                  ),
                ),
                Visibility(
                  visible: context.watch<SettingsModel>().getSendCrashlytics(),
                  child: _buildListTile(
                    title: "settings.send_anonymously".tr(),
                    subtitle: "settings.send_anonymously_desc".tr(),
                    trailing: CupertinoSwitch(
                      value: context
                          .watch<SettingsModel>()
                          .getSendCrashlyticsAnonymously(),
                      onChanged: (value) => context
                          .read<SettingsModel>()
                          .setSendCrashlyticsAnonymously(value),
                    ),
                  ),
                ),
                _buildListTile(
                  title: "알림 받기",
                  trailing: CupertinoSwitch(
                    value: context.watch<SettingsModel>().getReceiveAlarm(),
                    onChanged: (value) =>
                        context.read<SettingsModel>().setReceiveAlarm(value),
                  ),
                ),
                _buildListTile(
                  title: "settings.show_channel_talk_button".tr(),
                  trailing: CupertinoSwitch(
                    value: context
                        .watch<SettingsModel>()
                        .getShowsChannelTalkButton(),
                    onChanged: (value) {
                      context
                          .read<SettingsModel>()
                          .setShowsChannelTalkButton(value);

                      if (!value) {
                        ChannelTalk.hideChannelButton();
                      } else {
                        ChannelTalk.showChannelButton();
                      }
                    },
                  ),
                ),
                Visibility(
                  visible: kDebugMode,
                  child: _buildListTile(
                    title: "settings.throw_test".tr(),
                    subtitle: "settings.throw_test_desc".tr(),
                    onTap: () => throw Exception(),
                  ),
                ),
                _buildListTile(
                  title: "settings.reset_all".tr(),
                  onTap: () {
                    OTLNavigator.pushDialog(
                      context: context,
                      builder: (_) => OTLDialog(
                        type: OTLDialogType.resetSettings,
                        onTapPos: () =>
                            context.read<SettingsModel>().clearAllValues(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  title: "settings.about".tr(),
                  onTap: () => OTLNavigator.pushDialog(
                    context: context,
                    builder: (_) => OTLDialog(
                      type: OTLDialogType.about,
                      onTapContent: () =>
                          launchUrl(Uri.parse("mailto:$CONTACT")),
                      onTapPos: () => showLicensePage(
                        context: context,
                        applicationName: "",
                        applicationIcon:
                            Image.asset("assets/images/logo.png", height: 48.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
      {required String title,
      String? subtitle,
      Widget? trailing,
      void Function()? onTap,
      bool hasTopPadding = true}) {
    return Padding(
      padding: EdgeInsets.only(top: hasTopPadding ? 16 : 0),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: bodyBold),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: bodyRegular),
                    ]
                  ],
                ),
              ),
              if (trailing != null) trailing
            ],
          ),
        ),
      ),
    );
  }
}
