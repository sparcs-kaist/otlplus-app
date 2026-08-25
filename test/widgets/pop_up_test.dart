import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/pop_up.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/widgets/telemetry_synchronizer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  late SharedPreferencesStorePlatform originalPreferencesStore;
  late UrlLauncherPlatform originalUrlLauncher;
  late _FakeUrlLauncherPlatform urlLauncher;

  setUp(() {
    originalPreferencesStore = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
    SharedPreferences.resetStatic();
    originalUrlLauncher = UrlLauncherPlatform.instance;
    urlLauncher = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = urlLauncher;
  });

  tearDown(() {
    SharedPreferencesStorePlatform.instance = originalPreferencesStore;
    SharedPreferences.resetStatic();
    UrlLauncherPlatform.instance = originalUrlLauncher;
  });

  testWidgets('hide checkbox persists popup preference and links launch', (
    tester,
  ) async {
    final telemetry = _RecordingTelemetryCoordinator();
    await _pumpPopUpHarness(tester, telemetry);

    await tester.tap(find.text('다시 보지 않기'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('지원하러 가기'));
    await tester.pump(const Duration(milliseconds: 700));

    SharedPreferences.resetStatic();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('popup'), isFalse);
    expect(urlLauncher.urls, <String>['https://apply.sparcs.org/']);
    expect(telemetry.operations, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failing popup preference write does not escape the zone', (
    tester,
  ) async {
    SharedPreferencesStorePlatform.instance = _ThrowingPrefsStore();
    SharedPreferences.resetStatic();
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    await _pumpPopUpHarness(tester, telemetry);

    await runZonedGuarded<Future<void>>(() async {
      await tester.tap(find.text('다시 보지 않기'));
      await tester.pump(const Duration(milliseconds: 700));
    }, (error, stackTrace) => escapedErrors.add(error));

    expect(escapedErrors, isEmpty);
    expect(telemetry.operations, <String>['persist_popup_visibility']);
  });

  testWidgets('failing launch url from popup is observed and does not escape', (
    tester,
  ) async {
    urlLauncher.throwOnLaunch = true;
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    await _pumpPopUpHarness(tester, telemetry);

    await runZonedGuarded<Future<void>>(() async {
      await tester.tap(find.text('지원하러 가기'));
      await tester.pump(const Duration(milliseconds: 700));
    }, (error, stackTrace) => escapedErrors.add(error));

    expect(escapedErrors, isEmpty);
    expect(telemetry.operations, <String>['launch_popup_recruiting_url']);
    expect(find.byType(PopUp), findsOneWidget);

    final closeButton = find.byWidgetPredicate(
      (widget) => widget is IconTextButton && widget.icon == Icons.close,
    );
    await tester.tap(closeButton);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(PopUp), findsNothing);
  });
}

Future<void> _pumpPopUpHarness(
  WidgetTester tester,
  TelemetryCoordinator telemetry,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>.value(
          value: SettingsModel(forTest: true),
        ),
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
          child: const MaterialApp(home: _PopUpHarness()),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open popup'));
  await tester.pumpAndSettle();
  expect(find.byType(PopUp), findsOneWidget);
}

class _PopUpHarness extends StatelessWidget {
  const _PopUpHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => OTLNavigator.pushDialog<void>(
            context: context,
            builder: (_) => const PopUp(),
          ),
          child: const Text('open popup'),
        ),
      ),
    );
  }
}

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  final List<String> urls = <String>[];
  bool throwOnLaunch = false;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    if (throwOnLaunch) {
      throw PlatformException(code: 'no_handler');
    }
    return true;
  }
}

class _ThrowingPrefsStore extends SharedPreferencesStorePlatform {
  @override
  Future<bool> clear() async => true;

  @override
  Future<Map<String, Object>> getAll() async => <String, Object>{};

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    throw StateError('preferences write failed');
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
