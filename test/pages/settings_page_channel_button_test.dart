import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/pages/settings_page.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channelTalkChannel = MethodChannel('channel_talk_flutter');

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'toggling channel button on settings page does not leak unhandled exceptions',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });
      final telemetry = _RecordingTelemetryCoordinator();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channelTalkChannel, (call) async {
            if (call.method == 'hideChannelButton' ||
                call.method == 'showChannelButton') {
              throw MissingPluginException(
                'No implementation found for method ${call.method}',
              );
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channelTalkChannel, null);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<InfoModel>.value(
              value: InfoModel(forTest: true, telemetry: telemetry),
            ),
            ChangeNotifierProvider<SettingsModel>.value(
              value: SettingsModel(
                forTest: true,
                subscribeToTopic: (_) async {},
                unsubscribeFromTopic: (_) async {},
              ),
            ),
          ],
          child: EasyLocalization(
            supportedLocales: const [Locale('ko')],
            path: 'assets/translations',
            child: MaterialApp(home: SettingsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final label = find.text('채널톡 버튼 표시하기');
      await tester.ensureVisible(label);
      final tile = find.ancestor(of: label, matching: find.byType(Row)).first;
      final toggle = find.descendant(
        of: tile,
        matching: find.byType(CupertinoSwitch),
      );

      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(telemetry.operations, <String>[
        'update_channeltalk_channel_button',
      ]);
    },
  );
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
