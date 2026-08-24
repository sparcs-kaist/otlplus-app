import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/telemetry_synchronizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:otlplus/extensions/locale.dart';

Future<void> _guardPopUpCallback<T>(
  Future<T> Function() action,
  TelemetryCoordinator? telemetry, {
  required String operation,
}) async {
  try {
    await action();
  } catch (error, stackTrace) {
    await telemetry?.recordNonFatal(error, stackTrace, operation: operation);
  }
}

TelemetryCoordinator? _popUpTelemetry(BuildContext context) {
  return context
      .findAncestorWidgetOfExactType<TelemetrySynchronizer>()
      ?.telemetry;
}

class PopUp extends StatefulWidget {
  const PopUp({Key? key}) : super(key: key);

  @override
  State<PopUp> createState() => _PopUpState();
}

class _PopUpState extends State<PopUp> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.all(0.0),
      actionsPadding: EdgeInsets.only(top: 8.0),
      elevation: 0.0,
      content: _build23fRecruiting(context),
      actions: [
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16.0),
              bottomRight: Radius.circular(16.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconTextButton(
                onTap: () {
                  setState(() {
                    _checked = !_checked;
                  });
                  unawaited(
                    _guardPopUpCallback(
                      () async {
                        final preferences =
                            await SharedPreferences.getInstance();
                        await preferences.setBool('popup', !_checked);
                      },
                      _popUpTelemetry(context),
                      operation: 'persist_popup_visibility',
                    ),
                  );
                },
                tapEffect: ButtonTapEffect.none,
                icon: Icons.check_circle_outline,
                color: _checked ? OTLColor.pinksMain : OTLColor.grayA,
                spaceBetween: 8.0,
                text: 'popup.dont_show_again'.tr(),
                textStyle: bodyRegular.copyWith(
                  color: _checked ? OTLColor.grayF : OTLColor.grayA,
                ),
              ),
              IconTextButton(
                onTap: () async {
                  OTLNavigator.pop(context);
                },
                icon: Icons.close,
                color: OTLColor.grayF,
                tapEffect: ButtonTapEffect.darken,
                tapEffectColorRatio: 0.24,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _build23fRecruiting(BuildContext context) {
  return SingleChildScrollView(
    child: _buildImagePopup(
      context: context,
      imageAsset: 'assets/popups/23f-recruiting.png',
      button: FilledButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Color(0xFFEBA12A)),
        ),
        onPressed: () => unawaited(
          _guardPopUpCallback(
            () => launchUrl(Uri.parse('https://apply.sparcs.org/')),
            _popUpTelemetry(context),
            operation: 'launch_popup_recruiting_url',
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '지원하러 가기',
              style: bodyBold.copyWith(color: OTLColor.gray0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 8.0),
            Icon(Icons.arrow_forward, color: OTLColor.gray0),
          ],
        ),
      ),
    ),
  );
}

Widget _buildImagePopup({
  required BuildContext context,
  required String imageAsset,
  required Widget button,
}) {
  const imageWidth = 285.0;
  const imageHeight = 328.0;
  const buttonTop = 262.0;
  const dialogHorizontalInset = 40.0;
  final mediaQuery = MediaQuery.of(context);
  final availableWidth = math.max(
    0.0,
    mediaQuery.size.width -
        mediaQuery.padding.horizontal -
        dialogHorizontalInset * 2,
  );
  final width = math.min(imageWidth, availableWidth);
  final scale = width / imageWidth;

  return SizedBox(
    width: width,
    height: imageHeight * scale,
    child: Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Positioned.fill(child: Image.asset(imageAsset, fit: BoxFit.fill)),
        Positioned(
          top: buttonTop * scale,
          left: 0,
          right: 0,
          child: Center(child: button),
        ),
      ],
    ),
  );
}

// ignore: unused_element
Widget _buildAppEvent(BuildContext context) {
  final isEn = context.isEn;

  return SingleChildScrollView(
    child: _buildImagePopup(
      context: context,
      imageAsset: isEn
          ? 'assets/popups/app-event-image-en.png'
          : 'assets/popups/app-event-image.png',
      button: FilledButton(
        onPressed: () => unawaited(
          _guardPopUpCallback(
            () => launchUrl(
              Uri.parse(
                'https://docs.google.com/forms/d/e/1FAIpQLSfZbU_TFUPN53De_ihtS4ZK5Tb_nRDazRS7EYQgp3QWAYvyhQ/viewform',
              ),
            ),
            _popUpTelemetry(context),
            operation: 'launch_popup_event_url',
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('popup.join_the_event'.tr(), style: bodyBold),
            const SizedBox(width: 8.0),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    ),
  );
}

// ignore: unused_element
Widget _buildGraduatePlanner(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      children: [
        Text.rich(
          TextSpan(
            style: titleBold,
            children: <TextSpan>[
              TextSpan(text: '졸업플래너'),
              TextSpan(style: labelBold, text: 'BETA'),
              TextSpan(text: ' 서비스 이용 안내'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        Image.asset('assets/popups/graduate-planner.png', height: 128.0),
        const SizedBox(height: 8.0),
        Text('웹에서 지금 바로 만나보세요!', style: bodyRegular),
        const SizedBox(height: 8.0),
        FilledButton(
          onPressed: () => unawaited(
            _guardPopUpCallback(
              () => launchUrl(Uri.https("otl.sparcs.org", "planner")),
              _popUpTelemetry(context),
              operation: 'launch_graduate_planner_url',
            ),
          ),
          child: Text.rich(
            TextSpan(
              style: titleBold,
              children: <TextSpan>[
                TextSpan(text: '졸업플래너'),
                TextSpan(style: labelBold, text: 'BETA'),
                TextSpan(text: ' 이용하러 가기'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
