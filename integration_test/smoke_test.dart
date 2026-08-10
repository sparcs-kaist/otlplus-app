import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otlplus/main.dart' as app;
import 'package:otlplus/pages/login_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots past its initialization loading state', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 30));

    // The startup gate must release even when the backend is unreachable,
    // otherwise users are stranded on a blank spinner.
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'The app should finish initialization on a clean device.',
    );
  });

  testWidgets('signed-out launch lands on a usable screen', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 30));

    // A rendered route proves the widget tree mounted instead of showing the
    // white screen reported during auto-login.
    expect(find.byType(MaterialApp), findsWidgets);
    expect(
      find.byType(LoginPage),
      findsOneWidget,
      reason: 'A blank frame means startup never reached a usable route.',
    );
  });
}
