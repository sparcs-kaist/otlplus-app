import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/widgets/review_mode_control.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('tapping the second segment selects ReviewTab.latest', (
    tester,
  ) async {
    final model = HallOfFameModel();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: model,
        child: EasyLocalization(
          supportedLocales: const [Locale('ko')],
          path: 'assets/translations',
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const ReviewModeControl(),
                  Expanded(child: ListView(controller: model.scrollController)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.whatshot_outlined));
    await tester.pumpAndSettle();

    expect(model.selectedMode, ReviewTab.latest);
  });
}
