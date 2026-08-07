import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otlplus/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots past its initialization loading state', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 30));

    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'The app should finish initialization on a clean device.',
    );
  });
}
