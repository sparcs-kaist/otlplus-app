import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/home.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/widgets/telemetry_synchronizer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'shows notification consent dialog on first launch and persists choice',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final settings = _SettingsModel();
      final telemetry = _RecordingTelemetryCoordinator();
      final harnessKey = GlobalKey<_HomeHarnessState>();

      await tester.pumpWidget(
        _buildApp(
          settings: settings,
          telemetry: telemetry,
          harnessKey: harnessKey,
        ),
      );
      await tester.pump();

      expect(find.byType(OTLDialog), findsOneWidget);
      await tester.tap(find.text('동의'));
      await tester.pump();

      expect(settings.sendAlarmValues, <bool>[true]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notification_consent_shown'), isTrue);
      expect(tester.takeException(), isNull);

      await _disposeAndFlush(tester);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'notification_consent_shown': true,
      });
      final presetSettings = _SettingsModel();
      final presetTelemetry = _RecordingTelemetryCoordinator();
      final presetHarnessKey = GlobalKey<_HomeHarnessState>();

      await tester.pumpWidget(
        _buildApp(
          settings: presetSettings,
          telemetry: presetTelemetry,
          harnessKey: presetHarnessKey,
        ),
      );
      await tester.pump();

      expect(find.byType(OTLDialog), findsNothing);
      expect(presetSettings.sendAlarmValues, isEmpty);
      final exception = tester.takeException();
      await _disposeAndFlush(tester);

      expect(exception, isNull);
    },
  );

  testWidgets(
    'consent dialog callback after home disposal uses captured model without throwing',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final settings = _SettingsModel();
      final telemetry = _RecordingTelemetryCoordinator();
      final harnessKey = GlobalKey<_HomeHarnessState>();

      await tester.pumpWidget(
        _buildApp(
          settings: settings,
          telemetry: telemetry,
          harnessKey: harnessKey,
        ),
      );
      await tester.pump();
      expect(find.byType(OTLDialog), findsOneWidget);

      harnessKey.currentState!.hideHome();
      await tester.pump();
      await tester.tap(find.text('동의'));
      await tester.pump();

      final exception = tester.takeException();
      final sendAlarmValues = List<bool>.of(settings.sendAlarmValues);
      await _disposeAndFlush(tester);

      expect(exception, isNull);
      expect(sendAlarmValues, <bool>[true]);
    },
  );

  testWidgets(
    'failing setSendAlarm future is observed and does not escape the zone',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final settings = _SettingsModel(
        setSendAlarmError: PlatformException(code: 'offline'),
      );
      final telemetry = _RecordingTelemetryCoordinator();
      final harnessKey = GlobalKey<_HomeHarnessState>();
      final escapedErrors = <Object>[];

      await tester.pumpWidget(
        _buildApp(
          settings: settings,
          telemetry: telemetry,
          harnessKey: harnessKey,
        ),
      );
      await tester.pump();
      expect(find.byType(OTLDialog), findsOneWidget);

      await runZonedGuarded<Future<void>>(() async {
        await tester.tap(find.text('동의'));
        await tester.pump();
      }, (error, stackTrace) => escapedErrors.add(error));
      await tester.pump();

      final exception = tester.takeException();
      await _disposeAndFlush(tester);

      expect(escapedErrors, isEmpty);
      expect(telemetry.operations, <String>['set_notification_consent']);
      expect(exception, isNull);
    },
  );
}

Future<void> _disposeAndFlush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Widget _buildApp({
  required _SettingsModel settings,
  required _RecordingTelemetryCoordinator telemetry,
  required GlobalKey<_HomeHarnessState> harnessKey,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsModel>.value(value: settings),
      ChangeNotifierProvider<InfoModel>.value(
        value: InfoModel(infoRepository: InfoRepository(Dio()), forTest: true),
      ),
    ],
    child: EasyLocalization(
      supportedLocales: const [Locale('ko')],
      path: 'assets/translations',
      child: TelemetrySynchronizer(
        telemetry: telemetry,
        child: MaterialApp(home: _HomeHarness(key: harnessKey)),
      ),
    ),
  );
}

class _HomeHarness extends StatefulWidget {
  const _HomeHarness({super.key});

  @override
  State<_HomeHarness> createState() => _HomeHarnessState();
}

class _HomeHarnessState extends State<_HomeHarness> {
  bool _showHome = true;

  void hideHome() {
    setState(() => _showHome = false);
  }

  @override
  Widget build(BuildContext context) {
    return _showHome ? OTLHome() : const SizedBox.shrink();
  }
}

class _SettingsModel extends SettingsModel {
  _SettingsModel({this.setSendAlarmError}) : super(forTest: true);

  final Object? setSendAlarmError;
  final List<bool> sendAlarmValues = <bool>[];

  @override
  Future<void> setSendAlarm(bool newValue) {
    sendAlarmValues.add(newValue);
    if (setSendAlarmError != null) {
      return Future<void>.error(setSendAlarmError!);
    }
    return Future<void>.value();
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
