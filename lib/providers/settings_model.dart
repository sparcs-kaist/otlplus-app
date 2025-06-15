import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _kSendCrashlytics = 'sendCrashlytics';
final _kSendCrashlyticsAnonymously = 'sendCrashlyticsAnonymously';
final _kShowsChannelTalkButton = 'showsChannelTalkButton';

class SettingsModel extends ChangeNotifier {
  bool _sendCrashlytics = true;
  bool _sendCrashlyticsAnonymously = false;
  bool _showsChannelTalkButton = true;

  bool getSendCrashlytics() => _sendCrashlytics;
  void setSendCrashlytics(bool newValue) {
    _sendCrashlytics = newValue;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((instance) => instance.setBool(_kSendCrashlytics, newValue));
  }

  bool getSendCrashlyticsAnonymously() => _sendCrashlyticsAnonymously;
  void setSendCrashlyticsAnonymously(bool newValue) {
    _sendCrashlyticsAnonymously = newValue;
    notifyListeners();
    SharedPreferences.getInstance().then(
        (instance) => instance.setBool(_kSendCrashlyticsAnonymously, newValue));
  }

  bool getShowsChannelTalkButton() => _showsChannelTalkButton;
  void setShowsChannelTalkButton(bool newValue) {
    _showsChannelTalkButton = newValue;
    notifyListeners();
    SharedPreferences.getInstance().then(
        (instance) => instance.setBool(_kShowsChannelTalkButton, newValue));
  }

  SettingsModel({bool forTest = false}) {
    if (forTest) {
      _sendCrashlytics = true;
      _sendCrashlyticsAnonymously = false;
      _showsChannelTalkButton = true;
    } else {
      _loadPreferences();
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final instance = await SharedPreferences.getInstance();
      getAllValues(instance);
    } catch (e) {
      print("Error loading preferences: $e");
    }
  }

  void getAllValues(SharedPreferences instance) {
    final newSendCrashlytics = instance.getBool(_kSendCrashlytics) ?? true;
    final newSendCrashlyticsAnonymously = 
        instance.getBool(_kSendCrashlyticsAnonymously) ?? false;
    final newShowsChannelTalkButton = 
        instance.getBool(_kShowsChannelTalkButton) ?? true;
    
    if (_sendCrashlytics != newSendCrashlytics ||
        _sendCrashlyticsAnonymously != newSendCrashlyticsAnonymously ||
        _showsChannelTalkButton != newShowsChannelTalkButton) {
      _sendCrashlytics = newSendCrashlytics;
      _sendCrashlyticsAnonymously = newSendCrashlyticsAnonymously;
      _showsChannelTalkButton = newShowsChannelTalkButton;
      notifyListeners();
    }
  }

  Future<bool> clearAllValues() async {
    final instance = await SharedPreferences.getInstance();
    final success = await instance.clear();
    getAllValues(instance);
    return success;
  }
}
