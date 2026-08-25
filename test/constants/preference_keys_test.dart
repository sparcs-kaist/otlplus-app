import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/preference_keys.dart';

void main() {
  test('pins every preference key to its persisted string literal', () {
    expect(PreferenceKeys.hasAccount, 'hasAccount');
    expect(
      PreferenceKeys.notificationConsentShown,
      'notification_consent_shown',
    );
    expect(PreferenceKeys.popup, 'popup');
    expect(PreferenceKeys.userId, 'user_id');

    expect(PreferenceKeys.sendCrashlytics, 'sendCrashlytics');
    expect(
      PreferenceKeys.sendCrashlyticsAnonymously,
      'sendCrashlyticsAnonymously',
    );
    expect(PreferenceKeys.sendAnalytics, 'sendAnalytics');
    expect(PreferenceKeys.showsChannelTalkButton, 'showsChannelTalkButton');
    expect(PreferenceKeys.sendAlarm, 'sendAlarm');
    expect(PreferenceKeys.promotionAlarm, 'promotionAlarm');
    expect(PreferenceKeys.informationAlarm, 'informationAlarm');
    expect(PreferenceKeys.subjectSuggestionAlarm, 'subjectSuggestionAlarm');
  });
}
