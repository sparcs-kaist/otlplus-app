import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otlplus/main.dart' as app;
import 'package:otlplus/pages/login_page.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/wait_for.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The token vault is process-global and survives between tests, so every
  // test starts signed-out and removes the preferences keys it touched.
  setUp(() async {
    await StorageService().deleteTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasAccount', true);
  });

  tearDown(() async {
    await StorageService().deleteTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasAccount');
  });

  testWidgets('app boots past its initialization loading state', (
    tester,
  ) async {
    app.main();

    // The startup gate must release even when the backend is unreachable,
    // otherwise users are stranded on a blank spinner. Landing on either the
    // login page or the signed-in home proves initialization finished.
    await waitForAny(
      tester,
      <String, Finder>{
        'login': find.byType(LoginPage),
        'home': find.byKey(const Key('home_bottom_nav')),
      },
      stage: 'smoke-boot',
      timeout: const Duration(seconds: 60),
    );

    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'The app should finish initialization on a clean device.',
    );
  });

  testWidgets('signed-out launch lands on a usable screen', (tester) async {
    app.main();

    // A rendered route proves the widget tree mounted instead of showing the
    // white screen reported during auto-login.
    final outcome = await waitForAny(
      tester,
      <String, Finder>{
        'login': find.byType(LoginPage),
        'home': find.byKey(const Key('home_bottom_nav')),
      },
      stage: 'smoke-signed-out',
      timeout: const Duration(seconds: 60),
    );

    expect(outcome, 'login');
    expect(find.byType(MaterialApp), findsWidgets);
    expect(
      find.byType(LoginPage),
      findsOneWidget,
      reason: 'A blank frame means startup never reached a usable route.',
    );
  });
}
