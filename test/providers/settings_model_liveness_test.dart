import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('clearAllValues completes when unsubscribe hangs forever', () async {
    final neverCompletes = Completer<void>().future;
    final model = SettingsModel(
      forTest: true,
      subscribeToTopic: (_) async {},
      unsubscribeFromTopic: (_) => neverCompletes,
      topicTimeout: const Duration(milliseconds: 10),
    );

    model.setPromotionAlarm(true);
    model.setInformationAlarm(true);
    model.setSubjectSuggestionAlarm(true);
    await Future<void>.delayed(Duration.zero);

    await expectLater(model.clearAllValues(), completes);

    expect(model.getPromotionAlarm(), isFalse);
    expect(model.getInformationAlarm(), isFalse);
    expect(model.getSubjectSuggestionAlarm(), isFalse);
  });
}
