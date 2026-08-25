import 'dart:async';

import 'package:flutter/material.dart';
import 'package:otlplus/constants/preference_keys.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:otlplus/widgets/telemetry_synchronizer.dart';
import 'package:otlplus/pages/dictionary_page.dart';
import 'package:otlplus/pages/main_page.dart';
import 'package:otlplus/pages/review_page.dart';
import 'package:otlplus/pages/timetable_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _guardNotificationConsentFuture(
  Future<void> Function() action,
  TelemetryCoordinator? telemetry, {
  required String operation,
}) async {
  try {
    await action();
  } catch (error, stackTrace) {
    await telemetry?.recordNonFatal(error, stackTrace, operation: operation);
  }
}

class OTLHome extends StatefulWidget {
  const OTLHome({super.key});

  static String route = 'home';

  @override
  _OTLHomeState createState() => _OTLHomeState();
}

class _OTLHomeState extends State<OTLHome> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool get frontLayerVisible =>
      _controller.status == AnimationStatus.completed ||
      _controller.status == AnimationStatus.forward;
  late AnimationController _controller;
  late final Future<void> _localizationDelay;

  @override
  void initState() {
    super.initState();
    _localizationDelay = Future<void>.delayed(const Duration(milliseconds: 10));
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      value: 1.0,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsModel>();
      final telemetry = context
          .findAncestorWidgetOfExactType<TelemetrySynchronizer>()
          ?.telemetry;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (prefs.getBool(PreferenceKeys.notificationConsentShown) != true) {
        await OTLNavigator.pushDialog(
          context: context,
          builder: (_) => OTLDialog(
            type: OTLDialogType.notificationConsent,
            onTapPos: () {
              unawaited(
                _guardNotificationConsentFuture(
                  () => settings.setSendAlarm(true),
                  telemetry,
                  operation: 'set_notification_consent',
                ),
              );
              unawaited(
                _guardNotificationConsentFuture(
                  () async {
                    await prefs.setBool(
                      PreferenceKeys.notificationConsentShown,
                      true,
                    );
                  },
                  telemetry,
                  operation: 'persist_notification_consent_shown',
                ),
              );
            },
            onTapNeg: () {
              unawaited(
                _guardNotificationConsentFuture(
                  () => settings.setSendAlarm(false),
                  telemetry,
                  operation: 'set_notification_consent',
                ),
              );
              unawaited(
                _guardNotificationConsentFuture(
                  () async {
                    await prefs.setBool(
                      PreferenceKeys.notificationConsentShown,
                      true,
                    );
                  },
                  telemetry,
                  operation: 'persist_notification_consent_shown',
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Localization이 초기화되지 않는 오류가 있는 것으로 파악 > 일단 야매로 딜레이 줌
    return FutureBuilder(
      future: _localizationDelay,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return OTLScaffold(
          // extendBodyBehindAppBar: _currentIndex == 0,
          bottomNavigationBar: _buildBottomNavigationBar(context),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: LayoutBuilder(builder: _buildStack),
          ),
          resizeToAvoidBottomInset: false,
        );
      },
    );
  }

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    final layerTop = constraints.biggest.height;
    final layerAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(0, layerTop, 0, -layerTop),
      end: RelativeRect.fromLTRB(0, 0, 0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    return Stack(
      children: <Widget>[
        PositionedTransition(
          rect: layerAnimation,
          child: AnimatedOpacity(
            child: IndexedStack(
              index: _currentIndex,
              children: <Widget>[
                MainPage(
                  changeIndex: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                TimetablePage(),
                DictionaryPage(),
                ReviewPage(),
              ],
            ),
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 300),
            opacity: frontLayerVisible ? 1.0 : 0.0,
          ),
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      key: const Key('home_bottom_nav'),
      selectedFontSize: 12.0,
      unselectedFontSize: 12.0,
      enableFeedback: false,
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: context.tr('title.home'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.table_chart_outlined),
          label: context.tr("title.timetable"),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books_outlined),
          label: context.tr("title.dictionary"),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rate_review_outlined),
          label: context.tr("title.review"),
        ),
      ],
    );
  }
}
