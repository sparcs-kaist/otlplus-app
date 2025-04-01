import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/providers/notification_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

final _kSendCrashlytics = 'sendCrashlytics';
final _kSendCrashlyticsAnonymously = 'sendCrashlyticsAnonymously';
final _kShowsChannelTalkButton = 'showsChannelTalkButton';
final _kReceivePromotion = 'receivePromoiton';

final _kReceiveInfo = 'receiveInformation';
final _kReceiveSubjectSuggestion = 'receiveSubjectSuggestion';
final _kReceiveAlarm = 'receiveAlarm';
final _kDialog = 'dialog';


class SettingsModel extends ChangeNotifier {
  late bool _sendCrashlytics;
  late bool _sendCrashlyticsAnonymously;
  late bool _showsChannelTalkButton;
  late bool _receivePromotion;

  late bool _receiveInfo;
  late bool _receiveSubjectSuggestion;
  late bool _receiveAlarm;
  late bool _dialog;


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

  bool getReceivePromotion() => _receivePromotion;
  Future<void> setReceivePromotion(bool newValue) async {
    _receivePromotion = newValue;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((instance) => instance.setBool(_kReceivePromotion, newValue));
    newValue
        ? await FirebaseMessaging.instance.subscribeToTopic("promotion")
        : await FirebaseMessaging.instance.unsubscribeFromTopic("promotion");
  }

  bool getReceiveSubjectSuggestion() => _receiveSubjectSuggestion;
  Future<void> setReceiveSubjectSuggestion(bool newValue) async {
    _receiveSubjectSuggestion = newValue;
    notifyListeners();
    SharedPreferences.getInstance().then(
        (instance) => instance.setBool(_kReceiveSubjectSuggestion, newValue));
    newValue
        ? await FirebaseMessaging.instance
            .subscribeToTopic("subject_suggestion")
        : await FirebaseMessaging.instance
            .unsubscribeFromTopic("subject_suggestion");
  }

  bool getReceiveInfo() => _receiveInfo;
  Future<void> setReceiveInfo(bool newValue) async {
    _receiveInfo = newValue;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((instance) => instance.setBool(_kReceiveInfo, newValue));
    newValue
        ? await FirebaseMessaging.instance.subscribeToTopic("information")
        : await FirebaseMessaging.instance.unsubscribeFromTopic("information");
  }

  bool getReceiveAlarm() => _receiveAlarm;
  Future<void> setReceiveAlarm(bool newValue) async {
    bool hasPermission =
        await NotificationPermissionService.checkAndRequestPermission();
    _receiveAlarm = newValue;
    notifyListeners();
    debugPrint('new value : ${newValue}, permission : ${hasPermission}');
    if (newValue) {
      if (hasPermission) {
        SharedPreferences.getInstance()
            .then((instance) => instance.setBool(_kReceiveAlarm, newValue));
      } else {
        debugPrint('this case');
        openAppSettings();
      }
    } else {
      SharedPreferences.getInstance()
          .then((instance) => instance.setBool(_kReceiveAlarm, newValue));
    }
  }

  bool getDialog() => _dialog;
  void setDialog(bool newValue) {
    _dialog = newValue;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((instance) => instance.setBool(_kDialog, newValue));
  }


  SettingsModel({bool forTest = false}) {
    SharedPreferences.getInstance().then((instance) {
      getAllValues(instance);
    });

    if (forTest) {
      _sendCrashlytics = true;
      _sendCrashlyticsAnonymously = false;
      _showsChannelTalkButton = true;
      _receivePromotion = true;
      _receiveAlarm = true;
      _receiveInfo = true;
      _receiveSubjectSuggestion = true;
      _dialog = true;

    }
  }

  getAllValues(SharedPreferences instance) {
    _sendCrashlytics = instance.getBool(_kSendCrashlytics) ?? true;
    _sendCrashlyticsAnonymously =
        instance.getBool(_kSendCrashlyticsAnonymously) ?? false;
    _showsChannelTalkButton =
        instance.getBool(_kShowsChannelTalkButton) ?? true;
    _receivePromotion = instance.getBool(_kReceivePromotion) ?? false;

    _receiveAlarm = instance.getBool(_kReceiveAlarm) ?? true;
    _receiveInfo = instance.getBool(_kReceiveInfo) ?? true;
    _receiveSubjectSuggestion =
        instance.getBool(_kReceiveSubjectSuggestion) ?? true;
    _dialog = instance.getBool(_kDialog) ?? true;


    notifyListeners();
  }

  Future<bool> clearAllValues() async {
    final instance = await SharedPreferences.getInstance();
    final success = await instance.clear();
    getAllValues(instance);
    return success;
  }
}
