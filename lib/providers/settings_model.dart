import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _kSendCrashlytics = 'sendCrashlytics';
final _kSendCrashlyticsAnonymously = 'sendCrashlyticsAnonymously';
final _kSendAnalytics = 'sendAnalytics';
final _kShowsChannelTalkButton = 'showsChannelTalkButton';
final _kSendAlarm = 'sendAlarm';
final _kPromotionAlarm = 'promotionAlarm';
final _kInformationAlarm = 'informationAlarm';
final _kSubjectSuggestionAlarm = 'subjectSuggestionAlarm';

class SettingsModel extends ChangeNotifier {
  static Future<bool> loadCrashReportingEnabled() async {
    try {
      final instance = await SharedPreferences.getInstance();
      return instance.getBool(_kSendCrashlytics) ?? true;
    } catch (error) {
      debugPrint('Error loading crash reporting preference: $error');
      return false;
    }
  }

  SettingsModel({
    bool forTest = false,
    void Function(bool enabled)? onCrashReportingChanged,
  }) : _onCrashReportingChanged = onCrashReportingChanged {
    if (forTest) {
      _sendCrashlytics = true;
      _sendCrashlyticsAnonymously = false;
      _sendAnalytics = false;
      _showsChannelTalkButton = true;
      _sendAlarm = false;
      _promotionAlarm = false;
      _informationAlarm = false;
      _subjectSuggestionAlarm = false;
      _isLoaded = true;
      _onCrashReportingChanged?.call(_sendCrashlytics);
    } else {
      _loadPreferences();
    }
  }

  final void Function(bool enabled)? _onCrashReportingChanged;
  // Remain fail-closed until preferences are loaded successfully.
  bool _sendCrashlytics = false;
  bool _sendCrashlyticsAnonymously = false;
  bool _sendAnalytics = false;
  bool _isLoaded = false;
  bool _showsChannelTalkButton = true;
  bool _sendAlarm = false;
  bool _promotionAlarm = false;
  bool _informationAlarm = false;
  bool _subjectSuggestionAlarm = false;

  bool getSendCrashlytics() => _sendCrashlytics;
  void setSendCrashlytics(bool newValue) {
    _sendCrashlytics = newValue;
    _onCrashReportingChanged?.call(newValue);
    notifyListeners();
    SharedPreferences.getInstance().then(
      (instance) => instance.setBool(_kSendCrashlytics, newValue),
    );
  }

  bool getSendCrashlyticsAnonymously() => _sendCrashlyticsAnonymously;
  void setSendCrashlyticsAnonymously(bool newValue) {
    _sendCrashlyticsAnonymously = newValue;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (instance) => instance.setBool(_kSendCrashlyticsAnonymously, newValue),
    );
  }

  bool getSendAnalytics() => _sendAnalytics;
  Future<void> setSendAnalytics(bool newValue) async {
    final instance = await SharedPreferences.getInstance();
    await instance.setBool(_kSendAnalytics, newValue);
    _sendAnalytics = newValue;
    notifyListeners();
  }

  bool get isLoaded => _isLoaded;

  bool getShowsChannelTalkButton() => _showsChannelTalkButton;
  void setShowsChannelTalkButton(bool newValue) {
    _showsChannelTalkButton = newValue;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (instance) => instance.setBool(_kShowsChannelTalkButton, newValue),
    );
  }

  bool getSendAlarm() => _sendAlarm;
  Future<void> setSendAlarm(bool newValue) async {
    if (newValue) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          openAppSettings();
          return;
        }
      }
    }

    _sendAlarm = newValue;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (instance) => instance.setBool(_kSendAlarm, newValue),
    );

    _setPromotionAlarm(newValue);
    _setInformationAlarm(newValue);
    _setSubjectSuggestionAlarm(newValue);
  }

  bool getPromotionAlarm() => _promotionAlarm;
  void setPromotionAlarm(bool newValue) => _setPromotionAlarm(newValue);
  void _setPromotionAlarm(bool newValue) {
    _promotionAlarm = newValue;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (instance) => instance.setBool(_kPromotionAlarm, newValue),
    );
    if (newValue) {
      FirebaseMessaging.instance.subscribeToTopic('promotion');
    } else {
      FirebaseMessaging.instance.unsubscribeFromTopic('promotion');
    }
  }

  bool getInformationAlarm() => _informationAlarm;
  void setInformationAlarm(bool newValue) => _setInformationAlarm(newValue);
  void _setInformationAlarm(bool newValue) {
    _informationAlarm = newValue;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (instance) => instance.setBool(_kInformationAlarm, newValue),
    );
    if (newValue) {
      FirebaseMessaging.instance.subscribeToTopic('information');
    } else {
      FirebaseMessaging.instance.unsubscribeFromTopic('information');
    }
  }

  bool getSubjectSuggestionAlarm() => _subjectSuggestionAlarm;
  void setSubjectSuggestionAlarm(bool newValue) =>
      _setSubjectSuggestionAlarm(newValue);
  void _setSubjectSuggestionAlarm(bool newValue) {
    _subjectSuggestionAlarm = newValue;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (instance) => instance.setBool(_kSubjectSuggestionAlarm, newValue),
    );
    if (newValue) {
      FirebaseMessaging.instance.subscribeToTopic('subject_suggestion');
    } else {
      FirebaseMessaging.instance.unsubscribeFromTopic('subject_suggestion');
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final instance = await SharedPreferences.getInstance();
      getAllValues(instance);
    } catch (e) {
      _onCrashReportingChanged?.call(_sendCrashlytics);
      print("Error loading preferences: $e");
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  void getAllValues(SharedPreferences instance) {
    final newSendCrashlytics = instance.getBool(_kSendCrashlytics) ?? true;
    final newSendCrashlyticsAnonymously =
        instance.getBool(_kSendCrashlyticsAnonymously) ?? false;
    final newSendAnalytics = instance.getBool(_kSendAnalytics) ?? false;
    final newShowsChannelTalkButton =
        instance.getBool(_kShowsChannelTalkButton) ?? true;
    final newSendAlarm = instance.getBool(_kSendAlarm) ?? false;
    final newPromotionAlarm = instance.getBool(_kPromotionAlarm) ?? false;
    final newInformationAlarm = instance.getBool(_kInformationAlarm) ?? false;
    final newSubjectSuggestionAlarm =
        instance.getBool(_kSubjectSuggestionAlarm) ?? false;

    if (_sendCrashlytics != newSendCrashlytics ||
        _sendCrashlyticsAnonymously != newSendCrashlyticsAnonymously ||
        _sendAnalytics != newSendAnalytics ||
        _showsChannelTalkButton != newShowsChannelTalkButton ||
        _sendAlarm != newSendAlarm ||
        _promotionAlarm != newPromotionAlarm ||
        _informationAlarm != newInformationAlarm ||
        _subjectSuggestionAlarm != newSubjectSuggestionAlarm) {
      _sendCrashlytics = newSendCrashlytics;
      _sendCrashlyticsAnonymously = newSendCrashlyticsAnonymously;
      _sendAnalytics = newSendAnalytics;
      _showsChannelTalkButton = newShowsChannelTalkButton;
      _sendAlarm = newSendAlarm;
      _promotionAlarm = newPromotionAlarm;
      _informationAlarm = newInformationAlarm;
      _subjectSuggestionAlarm = newSubjectSuggestionAlarm;
      notifyListeners();
    }
    _onCrashReportingChanged?.call(_sendCrashlytics);
  }

  Future<bool> clearAllValues() async {
    final instance = await SharedPreferences.getInstance();
    final success = await instance.clear();

    FirebaseMessaging.instance.unsubscribeFromTopic('promotion');
    FirebaseMessaging.instance.unsubscribeFromTopic('information');
    FirebaseMessaging.instance.unsubscribeFromTopic('subject_suggestion');

    getAllValues(instance);
    return success;
  }
}
