import 'dart:async';

import 'package:channel_talk_flutter/channel_talk_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/preference_keys.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSendCrashlytics = PreferenceKeys.sendCrashlytics;
const _kSendCrashlyticsAnonymously = PreferenceKeys.sendCrashlyticsAnonymously;
const _kSendAnalytics = PreferenceKeys.sendAnalytics;
const _kShowsChannelTalkButton = PreferenceKeys.showsChannelTalkButton;
const _kSendAlarm = PreferenceKeys.sendAlarm;
const _kPromotionAlarm = PreferenceKeys.promotionAlarm;
const _kInformationAlarm = PreferenceKeys.informationAlarm;
const _kSubjectSuggestionAlarm = PreferenceKeys.subjectSuggestionAlarm;

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
    TelemetryCoordinator? telemetry,
    Future<void> Function(String topic)? subscribeToTopic,
    Future<void> Function(String topic)? unsubscribeFromTopic,
    Future<void> Function()? showChannelButton,
    Future<void> Function()? hideChannelButton,
    Duration topicTimeout = const Duration(seconds: 10),
  }) : _onCrashReportingChanged = onCrashReportingChanged,
       _telemetry = telemetry,
       _subscribeToTopic = subscribeToTopic ?? _defaultSubscribeToTopic,
       _unsubscribeFromTopic =
           unsubscribeFromTopic ?? _defaultUnsubscribeFromTopic,
       _showChannelButton = showChannelButton ?? _defaultShowChannelButton,
       _hideChannelButton = hideChannelButton ?? _defaultHideChannelButton,
       _topicTimeout = topicTimeout {
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

  static Future<void> _defaultSubscribeToTopic(String topic) {
    return FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  static Future<void> _defaultUnsubscribeFromTopic(String topic) {
    return FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  static Future<void> _defaultShowChannelButton() {
    return ChannelTalk.showChannelButton();
  }

  static Future<void> _defaultHideChannelButton() {
    return ChannelTalk.hideChannelButton();
  }

  final void Function(bool enabled)? _onCrashReportingChanged;
  final TelemetryCoordinator? _telemetry;
  final Future<void> Function(String topic) _subscribeToTopic;
  final Future<void> Function(String topic) _unsubscribeFromTopic;
  final Future<void> Function() _showChannelButton;
  final Future<void> Function() _hideChannelButton;
  final Duration _topicTimeout;

  // Remain fail-closed until preferences are loaded successfully.
  bool _sendCrashlytics = false;
  bool _sendCrashlyticsAnonymously = false;
  bool _sendAnalytics = false;
  bool _isLoaded = false;
  bool _isDisposed = false;
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
    unawaited(
      _guardedPersist('persist_send_crashlytics', _kSendCrashlytics, newValue),
    );
  }

  bool getSendCrashlyticsAnonymously() => _sendCrashlyticsAnonymously;
  void setSendCrashlyticsAnonymously(bool newValue) {
    _sendCrashlyticsAnonymously = newValue;
    notifyListeners();
    unawaited(
      _guardedPersist(
        'persist_send_crashlytics_anonymously',
        _kSendCrashlyticsAnonymously,
        newValue,
      ),
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
    unawaited(
      _guardedPersist(
        'persist_shows_channel_talk_button',
        _kShowsChannelTalkButton,
        newValue,
      ),
    );
  }

  Future<void> applyChannelButtonVisibility(bool visible) async {
    setShowsChannelTalkButton(visible);
    try {
      if (visible) {
        await _showChannelButton();
      } else {
        await _hideChannelButton();
      }
    } catch (error, stackTrace) {
      await _telemetry?.recordNonFatal(
        error,
        stackTrace,
        operation: 'update_channeltalk_channel_button',
      );
    }
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
    unawaited(_guardedPersist('persist_send_alarm', _kSendAlarm, newValue));

    _setPromotionAlarm(newValue);
    _setInformationAlarm(newValue);
    _setSubjectSuggestionAlarm(newValue);
  }

  Future<void> _guardedPersist(String operation, String key, bool value) async {
    try {
      final instance = await SharedPreferences.getInstance();
      await instance.setBool(key, value);
    } catch (error, stackTrace) {
      await _telemetry?.recordNonFatal(error, stackTrace, operation: operation);
    }
  }

  Future<void> _guardedTopic(
    String operation,
    Future<void> Function() action,
  ) async {
    try {
      await action().timeout(_topicTimeout);
    } catch (error, stackTrace) {
      await _telemetry?.recordNonFatal(error, stackTrace, operation: operation);
    }
  }

  bool getPromotionAlarm() => _promotionAlarm;
  void setPromotionAlarm(bool newValue) => _setPromotionAlarm(newValue);
  void _setPromotionAlarm(bool newValue) {
    _promotionAlarm = newValue;
    notifyListeners();
    unawaited(
      _guardedPersist('persist_promotion_alarm', _kPromotionAlarm, newValue),
    );
    if (newValue) {
      unawaited(
        _guardedTopic(
          'subscribe_promotion',
          () => _subscribeToTopic('promotion'),
        ),
      );
    } else {
      unawaited(
        _guardedTopic(
          'unsubscribe_promotion',
          () => _unsubscribeFromTopic('promotion'),
        ),
      );
    }
  }

  bool getInformationAlarm() => _informationAlarm;
  void setInformationAlarm(bool newValue) => _setInformationAlarm(newValue);
  void _setInformationAlarm(bool newValue) {
    _informationAlarm = newValue;
    notifyListeners();
    unawaited(
      _guardedPersist(
        'persist_information_alarm',
        _kInformationAlarm,
        newValue,
      ),
    );
    if (newValue) {
      unawaited(
        _guardedTopic(
          'subscribe_information',
          () => _subscribeToTopic('information'),
        ),
      );
    } else {
      unawaited(
        _guardedTopic(
          'unsubscribe_information',
          () => _unsubscribeFromTopic('information'),
        ),
      );
    }
  }

  bool getSubjectSuggestionAlarm() => _subjectSuggestionAlarm;
  void setSubjectSuggestionAlarm(bool newValue) =>
      _setSubjectSuggestionAlarm(newValue);
  void _setSubjectSuggestionAlarm(bool newValue) {
    _subjectSuggestionAlarm = newValue;
    notifyListeners();
    unawaited(
      _guardedPersist(
        'persist_subject_suggestion_alarm',
        _kSubjectSuggestionAlarm,
        newValue,
      ),
    );
    if (newValue) {
      unawaited(
        _guardedTopic(
          'subscribe_subject_suggestion',
          () => _subscribeToTopic('subject_suggestion'),
        ),
      );
    } else {
      unawaited(
        _guardedTopic(
          'unsubscribe_subject_suggestion',
          () => _unsubscribeFromTopic('subject_suggestion'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final instance = await SharedPreferences.getInstance();
      getAllValues(instance);
    } catch (e) {
      _onCrashReportingChanged?.call(_sendCrashlytics);
      debugPrint("Error loading preferences: $e");
    } finally {
      _isLoaded = true;
      if (!_isDisposed) {
        notifyListeners();
      }
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
    getAllValues(instance);

    await Future.wait(<Future<void>>[
      _guardedTopic(
        'clear_unsubscribe_promotion',
        () => _unsubscribeFromTopic('promotion'),
      ),
      _guardedTopic(
        'clear_unsubscribe_information',
        () => _unsubscribeFromTopic('information'),
      ),
      _guardedTopic(
        'clear_unsubscribe_subject_suggestion',
        () => _unsubscribeFromTopic('subject_suggestion'),
      ),
    ]);

    return success;
  }
}
