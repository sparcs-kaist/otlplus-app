import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/pages/settings_page.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:otlplus/widgets/telemetry_synchronizer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('toggles invoke settings model methods', (tester) async {
    final telemetry = _RecordingTelemetryCoordinator();
    final settings = _SettingsModel(telemetry: telemetry);
    await _pumpSettingsPage(tester, settings, telemetry);

    await _tapSwitch(tester, '알림 받기');
    await _tapSwitch(tester, '익명 사용 분석 전송');
    await _tapReset(tester);

    expect(settings.sendAlarmValues, <bool>[true]);
    expect(settings.sendAnalyticsValues, <bool>[true]);
    expect(settings.clearAllValuesCallCount, 1);
    expect(telemetry.operations, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failing toggle futures are observed and do not escape the zone',
    (tester) async {
      final telemetry = _RecordingTelemetryCoordinator();
      final settings = _SettingsModel(
        telemetry: telemetry,
        failSendAlarm: true,
        failSendAnalytics: true,
        failClearAllValues: true,
      );
      final escapedErrors = <Object>[];
      await _pumpSettingsPage(tester, settings, telemetry);

      await _runInGuardedZone(() => _tapSwitch(tester, '알림 받기'), escapedErrors);
      await _runInGuardedZone(
        () => _tapSwitch(tester, '익명 사용 분석 전송'),
        escapedErrors,
      );
      await _runInGuardedZone(() => _tapReset(tester), escapedErrors);

      expect(escapedErrors, isEmpty);
      expect(telemetry.operations, <String>[
        'set_send_alarm',
        'set_send_analytics',
        'clear_all_settings',
      ]);
    },
  );

  testWidgets('channel button behavior from previous fix is unchanged', (
    tester,
  ) async {
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    final settings = SettingsModel(
      forTest: true,
      telemetry: telemetry,
      showChannelButton: () =>
          Future<void>.error(PlatformException(code: 'show_failed')),
      hideChannelButton: () =>
          Future<void>.error(PlatformException(code: 'hide_failed')),
      subscribeToTopic: (_) async {},
      unsubscribeFromTopic: (_) async {},
    );
    await _pumpSettingsPage(tester, settings, telemetry);

    await _runInGuardedZone(
      () => _tapSwitch(tester, '채널톡 버튼 표시하기'),
      escapedErrors,
    );

    expect(escapedErrors, isEmpty);
    expect(telemetry.operations, <String>['update_channeltalk_channel_button']);
  });
}

Future<void> _pumpSettingsPage(
  WidgetTester tester,
  SettingsModel settings,
  TelemetryCoordinator telemetry,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 2400);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>.value(value: settings),
        ChangeNotifierProvider<InfoModel>.value(
          value: InfoModel(
            infoRepository: InfoRepository(Dio()),
            forTest: true,
          ),
        ),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('ko')],
        path: 'assets/translations',
        child: TelemetrySynchronizer(
          telemetry: telemetry,
          child: MaterialApp(home: SettingsPage()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapSwitch(WidgetTester tester, String label) async {
  final labelFinder = find.text(label);
  await tester.ensureVisible(labelFinder);
  final row = find.ancestor(of: labelFinder, matching: find.byType(Row)).first;
  final toggle = find.descendant(
    of: row,
    matching: find.byType(CupertinoSwitch),
  );
  expect(toggle, findsOneWidget);
  await tester.tap(toggle);
  await tester.pump();
  await tester.pump(Duration.zero);
}

Future<void> _tapReset(WidgetTester tester) async {
  final reset = find.text('모든 설정 데이터 초기화');
  await tester.ensureVisible(reset);
  await tester.tap(reset);
  await tester.pumpAndSettle();
  await tester.tap(find.text('초기화'));
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _runInGuardedZone(
  Future<void> Function() action,
  List<Object> escapedErrors,
) async {
  await runZonedGuarded<Future<void>>(
    action,
    (error, stackTrace) => escapedErrors.add(error),
  );
}

class _SettingsModel extends SettingsModel {
  _SettingsModel({
    required TelemetryCoordinator telemetry,
    this.failSendAlarm = false,
    this.failSendAnalytics = false,
    this.failClearAllValues = false,
  }) : super(
         forTest: true,
         telemetry: telemetry,
         subscribeToTopic: (_) async {},
         unsubscribeFromTopic: (_) async {},
       );

  final bool failSendAlarm;
  final bool failSendAnalytics;
  final bool failClearAllValues;
  final List<bool> sendAlarmValues = <bool>[];
  final List<bool> sendAnalyticsValues = <bool>[];
  int clearAllValuesCallCount = 0;
  bool _sendAlarm = false;
  bool _sendAnalytics = false;

  @override
  bool getSendAlarm() => _sendAlarm;

  @override
  Future<void> setSendAlarm(bool newValue) {
    sendAlarmValues.add(newValue);
    if (failSendAlarm) {
      return Future<void>.error(
        PlatformException(code: 'set_send_alarm_failed'),
      );
    }
    _sendAlarm = newValue;
    notifyListeners();
    return Future<void>.value();
  }

  @override
  bool getSendAnalytics() => _sendAnalytics;

  @override
  Future<void> setSendAnalytics(bool newValue) {
    sendAnalyticsValues.add(newValue);
    if (failSendAnalytics) {
      return Future<void>.error(
        PlatformException(code: 'set_send_analytics_failed'),
      );
    }
    _sendAnalytics = newValue;
    notifyListeners();
    return Future<void>.value();
  }

  @override
  Future<bool> clearAllValues() {
    clearAllValuesCallCount++;
    if (failClearAllValues) {
      return Future<bool>.error(
        PlatformException(code: 'clear_all_values_failed'),
      );
    }
    return Future<bool>.value(true);
  }
}

class _RecordingTelemetryCoordinator extends TelemetryCoordinator {
  _RecordingTelemetryCoordinator()
    : super(
        analytics: _NoOpAnalyticsClient(),
        crashReporting: _NoOpCrashReportingClient(),
      );

  final List<String> operations = <String>[];

  @override
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) async {
    operations.add(operation);
  }
}

class _NoOpAnalyticsClient implements AnalyticsClient {
  @override
  Future<void> capture(String eventName) async {}

  @override
  Future<void> identify(String distinctId) async {}

  @override
  Future<void> disable() async {}

  @override
  Future<void> enable() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> reset() async {}
}

class _NoOpCrashReportingClient implements CrashReportingClient {
  @override
  Future<void> deleteUnsentReports() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
    required String reason,
  }) async {}

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserIdentifier(String identifier) async {}
}
