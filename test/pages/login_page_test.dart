import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/pages/login_page.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesStorePlatform originalPrefsStore;
  late WebViewPlatform? originalWebViewPlatform;
  late _DeferredPrefsStore prefsStore;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    originalPrefsStore = SharedPreferencesStorePlatform.instance;
    originalWebViewPlatform = WebViewPlatform.instance;
    prefsStore = _DeferredPrefsStore();
    SharedPreferencesStorePlatform.instance = prefsStore;
    SharedPreferences.resetStatic();
    WebViewPlatform.instance = _FakeWebViewPlatform();
  });

  tearDown(() {
    SharedPreferencesStorePlatform.instance = originalPrefsStore;
    SharedPreferences.resetStatic();
    if (originalWebViewPlatform != null) {
      WebViewPlatform.instance = originalWebViewPlatform!;
    }
  });

  testWidgets('shows account deleted dialog when hasAccount is false', (
    tester,
  ) async {
    final escapedErrors = <Object>[];
    OTLDialogType? dialogType;
    Object? exception;

    await runZonedGuarded<Future<void>>(() async {
      await tester.pumpWidget(_buildApp());

      prefsStore.complete(<String, Object>{'hasAccount': false});
      await _pumpFrames(tester);

      final dialogFinder = find.byType(OTLDialog);
      final dialogElements = dialogFinder.evaluate().toList();
      if (dialogElements.isNotEmpty) {
        dialogType = (dialogElements.first.widget as OTLDialog).type;
        Navigator.of(dialogElements.first, rootNavigator: true).pop();
        await tester.pump(const Duration(seconds: 1));
      }
      exception = tester.takeException();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }, (error, stackTrace) => escapedErrors.add(error));

    expect(dialogType, OTLDialogType.accountDeleted);
    expect(exception, isNull);
    expect(escapedErrors, isEmpty);
  });

  testWidgets(
    'prefs callback completing after login page disposal does not throw',
    (tester) async {
      final harnessKey = GlobalKey<_LoginPageHarnessState>();
      final escapedErrors = <Object>[];
      var getAllCallCount = 0;
      var loginPageRemoved = false;
      var dialogFound = false;
      Object? exception;

      await runZonedGuarded<Future<void>>(() async {
        await tester.pumpWidget(_buildApp(harnessKey: harnessKey));
        getAllCallCount = prefsStore.getAllCallCount;

        harnessKey.currentState!.hideLoginPage();
        await tester.pump();
        loginPageRemoved = find.byType(LoginPage).evaluate().isEmpty;

        prefsStore.complete(<String, Object>{'hasAccount': false});
        await _pumpFrames(tester);

        exception = tester.takeException();
        dialogFound = find.byType(OTLDialog).evaluate().isNotEmpty;

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }, (error, stackTrace) => escapedErrors.add(error));

      expect(getAllCallCount, 1);
      expect(loginPageRemoved, isTrue);
      expect(exception, isNull);
      expect(dialogFound, isFalse);
      expect(escapedErrors, isEmpty);
    },
  );

  testWidgets('no dialog when hasAccount is true', (tester) async {
    final escapedErrors = <Object>[];
    var dialogFound = false;
    Object? exception;

    await runZonedGuarded<Future<void>>(() async {
      await tester.pumpWidget(_buildApp());

      prefsStore.complete(<String, Object>{'hasAccount': true});
      await _pumpFrames(tester);

      dialogFound = find.byType(OTLDialog).evaluate().isNotEmpty;
      exception = tester.takeException();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }, (error, stackTrace) => escapedErrors.add(error));

    expect(dialogFound, isFalse);
    expect(exception, isNull);
    expect(escapedErrors, isEmpty);
  });
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump();
  }
}

Widget _buildApp({GlobalKey<_LoginPageHarnessState>? harnessKey}) {
  final storageService = StorageService();
  return MultiProvider(
    providers: [
      Provider<StorageService>.value(value: storageService),
      ChangeNotifierProvider<AuthModel>.value(value: AuthModel(storageService)),
    ],
    child: EasyLocalization(
      supportedLocales: const [Locale('ko')],
      path: 'assets/translations',
      child: MaterialApp(home: _LoginPageHarness(key: harnessKey)),
    ),
  );
}

class _LoginPageHarness extends StatefulWidget {
  const _LoginPageHarness({super.key});

  @override
  State<_LoginPageHarness> createState() => _LoginPageHarnessState();
}

class _LoginPageHarnessState extends State<_LoginPageHarness> {
  bool _showLoginPage = true;

  void hideLoginPage() {
    setState(() => _showLoginPage = false);
  }

  @override
  Widget build(BuildContext context) {
    return _showLoginPage ? LoginPage() : const SizedBox.shrink();
  }
}

class _DeferredPrefsStore extends SharedPreferencesStorePlatform {
  final Completer<Map<String, Object>> _getAllCompleter =
      Completer<Map<String, Object>>.sync();

  int getAllCallCount = 0;

  void complete(Map<String, Object> values) {
    _getAllCompleter.complete(<String, Object>{
      for (final entry in values.entries) 'flutter.${entry.key}': entry.value,
    });
  }

  @override
  Future<bool> clear() async => true;

  @override
  Future<Map<String, Object>> getAll() {
    getAllCallCount++;
    return _getAllCompleter.future;
  }

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      true;
}

class _FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => _FakePlatformNavigationDelegate(params);

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => _FakePlatformWebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _FakePlatformWebViewWidget(params);
}

class _FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  _FakePlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}
}

class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController(super.params) : super.implementation();

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async {}
}

class _FakePlatformWebViewWidget extends PlatformWebViewWidget {
  _FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
