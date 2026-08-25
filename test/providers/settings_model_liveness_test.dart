import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

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

  test(
    'does not notify listeners after disposal when preferences load late',
    () async {
      final originalStore = SharedPreferencesStorePlatform.instance;
      final deferredStore = _DeferredPrefsStore();
      SharedPreferencesStorePlatform.instance = deferredStore;
      SharedPreferences.resetStatic();
      addTearDown(() {
        SharedPreferencesStorePlatform.instance = originalStore;
        SharedPreferences.resetStatic();
      });

      final model = _TrackingSettingsModel();
      model.dispose();

      deferredStore.complete(<String, Object>{
        'sendCrashlytics': false,
        'sendCrashlyticsAnonymously': false,
        'sendAnalytics': false,
        'showsChannelTalkButton': true,
        'sendAlarm': false,
        'promotionAlarm': false,
        'informationAlarm': false,
        'subjectSuggestionAlarm': false,
      });
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(model.notificationsAfterDispose, 0);
    },
  );
}

class _TrackingSettingsModel extends SettingsModel {
  bool _disposed = false;
  int notificationsAfterDispose = 0;

  @override
  void notifyListeners() {
    if (_disposed) {
      notificationsAfterDispose += 1;
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _DeferredPrefsStore extends SharedPreferencesStorePlatform {
  final Completer<Map<String, Object>> _values =
      Completer<Map<String, Object>>.sync();

  void complete(Map<String, Object> values) {
    _values.complete(<String, Object>{
      for (final entry in values.entries) 'flutter.${entry.key}': entry.value,
    });
  }

  @override
  Future<bool> clear() async => true;

  @override
  Future<Map<String, Object>> getAll() => _values.future;

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      true;
}
