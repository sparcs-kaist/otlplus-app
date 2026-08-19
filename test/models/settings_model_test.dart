import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads stored crash reporting consent before startup', () async {
    SharedPreferences.setMockInitialValues({});
    final model = SettingsModel(forTest: true);
    model.setSendCrashlytics(false);
    await Future<void>.delayed(Duration.zero);

    expect(await SettingsModel.loadCrashReportingEnabled(), isFalse);

    SharedPreferences.setMockInitialValues({});

    expect(await SettingsModel.loadCrashReportingEnabled(), isTrue);
  });

  test('notifies crash consent changes synchronously', () async {
    SharedPreferences.setMockInitialValues({});
    final observedValues = <bool>[];
    final model = SettingsModel(
      forTest: true,
      onCrashReportingChanged: observedValues.add,
    );

    expect(observedValues, [true]);

    model.setSendCrashlytics(false);
    await Future<void>.delayed(Duration.zero);

    expect(observedValues, [true, false]);

    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    model.getAllValues(preferences);

    expect(observedValues, [true, false, true]);
  });
}
