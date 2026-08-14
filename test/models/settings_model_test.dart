import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notifies crash consent changes synchronously', () async {
    SharedPreferences.setMockInitialValues({});
    final observedValues = <bool>[];
    final model = SettingsModel(
      forTest: true,
      onCrashReportingChanged: observedValues.add,
    );

    expect(observedValues, [true]);

    model.setSendCrashlytics(false);

    expect(observedValues, [true, false]);
    await Future<void>.delayed(Duration.zero);
  });
}
