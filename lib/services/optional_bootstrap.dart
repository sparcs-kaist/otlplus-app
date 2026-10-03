import 'dart:async';
import 'dart:io';

import 'package:channel_talk_flutter/channel_talk_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:otlplus/constants/preference_keys.dart';
import 'package:otlplus/services/channel_talk_readiness.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _showsChannelTalkButtonKey = PreferenceKeys.showsChannelTalkButton;

class OptionalBootstrap {
  OptionalBootstrap({
    required this.recordNonFatal,
    Future<void> Function()? requestPermission,
    Future<String?> Function()? getAPNSToken,
    Future<String?> Function()? getToken,
    Stream<String> Function()? onTokenRefresh,
    Future<bool?> Function({String? memberHash})? channelTalkBoot,
    Future<void> Function(String token)? initPushToken,
    Future<bool> Function()? shouldShowChannelButton,
    Future<void> Function()? showChannelButton,
    Future<void> Function()? hideChannelButton,
    Future<void> Function(Duration duration)? delay,
    ChannelTalkReadiness? channelTalkReadiness,
    bool? isIOS,
    this.apnsRetryDelay = const Duration(milliseconds: 500),
    this.apnsMaxAttempts = 6,
    this.tokenTimeout = const Duration(seconds: 10),
    this.bootTimeout = const Duration(seconds: 10),
    this.pushTokenTimeout = const Duration(seconds: 10),
  }) : requestPermission = requestPermission ?? _requestPermission,
       getAPNSToken = getAPNSToken ?? _getAPNSToken,
       getToken = getToken ?? _getToken,
       onTokenRefresh = onTokenRefresh ?? _onTokenRefresh,
       channelTalkBoot = channelTalkBoot ?? _channelTalkBoot,
       initPushToken = initPushToken ?? _initPushToken,
       _shouldShowChannelButton =
           shouldShowChannelButton ?? _defaultShouldShowChannelButton,
       showChannelButton = showChannelButton ?? _showChannelButton,
       _hideChannelButton = hideChannelButton ?? _defaultHideChannelButton,
       delay = delay ?? _delay,
       _channelTalkReadiness =
           channelTalkReadiness ?? sharedChannelTalkReadiness,
       isIOS = isIOS ?? (!kIsWeb && Platform.isIOS);

  final Future<void> Function() requestPermission;
  final Future<String?> Function() getAPNSToken;
  final Future<String?> Function() getToken;
  final Stream<String> Function() onTokenRefresh;
  final Future<bool?> Function({String? memberHash}) channelTalkBoot;
  final Future<void> Function(String token) initPushToken;
  final Future<bool> Function() _shouldShowChannelButton;
  final Future<void> Function() showChannelButton;
  final Future<void> Function() _hideChannelButton;
  final Future<void> Function(Duration duration) delay;
  final ChannelTalkReadiness _channelTalkReadiness;
  final Future<void> Function(Object error, StackTrace stack) recordNonFatal;
  final bool isIOS;
  final Duration apnsRetryDelay;
  final int apnsMaxAttempts;
  final Duration tokenTimeout;
  final Duration bootTimeout;
  final Duration pushTokenTimeout;

  StreamSubscription<String>? tokenRefreshSubscription;
  Future<void> _pushTokenRegistrations = Future<void>.value();
  bool _channelTalkBooted = false;
  String? _pendingPushToken;
  String? _lastRegisteredPushToken;

  Future<void> run() async {
    String? token;

    await _subscribeToTokenRefresh();

    try {
      await requestPermission();
      if (isIOS) {
        if (await _waitForAPNSToken()) {
          token = await _getTokenWithTimeout();
        }
      } else {
        token = await _getTokenWithTimeout();
      }
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
    }

    if (_pendingPushToken == null && token != null && token.isNotEmpty) {
      _pendingPushToken = token;
    }

    bool? booted;
    try {
      booted = await channelTalkBoot(memberHash: token).timeout(bootTimeout);
    } catch (error, stack) {
      _channelTalkReadiness.markUnavailable();
      await _cancelTokenRefreshSubscription();
      await _recordNonFatalSafely(error, stack);
      return;
    }
    if (booted != true) {
      _channelTalkReadiness.markUnavailable();
      await _cancelTokenRefreshSubscription();
      await _recordNonFatalSafely(
        StateError('ChannelTalk.boot returned false'),
        StackTrace.current,
      );
      return;
    }

    _channelTalkBooted = true;
    _channelTalkReadiness.markBooted();
    await _flushPendingPushToken();

    try {
      if (await _shouldShowChannelButton()) {
        await showChannelButton();
      } else {
        await _hideChannelButton();
      }
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
    }
  }

  Future<void> _subscribeToTokenRefresh() async {
    if (tokenRefreshSubscription != null) return;

    try {
      tokenRefreshSubscription = onTokenRefresh().listen(
        (token) {
          if (token.isEmpty) return;
          _pendingPushToken = token;
          if (_channelTalkBooted) {
            unawaited(_flushPendingPushToken());
          }
        },
        onError: (Object error, StackTrace stack) {
          unawaited(_recordNonFatalSafely(error, stack));
        },
      );
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
    }
  }

  Future<void> _flushPendingPushToken() async {
    final token = _pendingPushToken;
    _pendingPushToken = null;
    if (token == null || token.isEmpty) return;

    await _serializePushTokenRegistration(token);
    if (_channelTalkBooted && _pendingPushToken != null) {
      await _flushPendingPushToken();
    }
  }

  Future<void> _serializePushTokenRegistration(String token) {
    final previousRegistration = _pushTokenRegistrations.catchError((_) {});
    final registration = previousRegistration.then((_) async {
      if (token == _lastRegisteredPushToken) return;

      try {
        await initPushToken(token).timeout(pushTokenTimeout);
        _lastRegisteredPushToken = token;
      } catch (error, stack) {
        await _recordNonFatalSafely(error, stack);
      }
    });
    _pushTokenRegistrations = registration;
    return registration;
  }

  Future<void> _cancelTokenRefreshSubscription() async {
    final subscription = tokenRefreshSubscription;
    tokenRefreshSubscription = null;
    try {
      await subscription?.cancel();
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
    }
  }

  Future<void> dispose() => _cancelTokenRefreshSubscription();

  Future<bool> _waitForAPNSToken() async {
    for (var attempt = 1; attempt <= apnsMaxAttempts; attempt += 1) {
      if (await getAPNSToken() != null) return true;
      if (attempt < apnsMaxAttempts) await delay(apnsRetryDelay);
    }

    await _recordNonFatalSafely(
      StateError('APNS token unavailable after $apnsMaxAttempts attempts'),
      StackTrace.current,
    );
    return false;
  }

  Future<String?> _getTokenWithTimeout() {
    return getToken().timeout(
      tokenTimeout,
      onTimeout: () async {
        await _recordNonFatalSafely(
          StateError('FCM token timed out after ${tokenTimeout.inSeconds}s'),
          StackTrace.current,
        );
        return null;
      },
    );
  }

  Future<void> _recordNonFatalSafely(Object error, StackTrace stack) async {
    try {
      await recordNonFatal(error, stack);
    } catch (_) {}
  }

  static Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );
  }

  static Future<String?> _getAPNSToken() {
    return FirebaseMessaging.instance.getAPNSToken();
  }

  static Future<String?> _getToken() {
    return FirebaseMessaging.instance.getToken();
  }

  static Stream<String> _onTokenRefresh() {
    return FirebaseMessaging.instance.onTokenRefresh;
  }

  static Future<void> _delay(Duration duration) {
    return Future<void>.delayed(duration);
  }

  static Future<bool?> _channelTalkBoot({String? memberHash}) {
    return ChannelTalk.boot(
      pluginKey: '0abc4b50-9e66-4b45-b910-eb654a481f08',
      memberHash: memberHash,
      language: Language.korean,
      trackDefaultEvent: false,
      appearance: Appearance.light,
      channelButtonOption: ChannelButtonOption(
        position: ChannelButtonPosition.right,
        xMargin: 16,
        yMargin: 130,
      ),
    );
  }

  static Future<void> _initPushToken(String token) async {
    await ChannelTalk.initPushToken(deviceToken: token);
  }

  static Future<bool> _defaultShouldShowChannelButton() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_showsChannelTalkButtonKey) ?? true;
  }

  static Future<void> _showChannelButton() async {
    await ChannelTalk.showChannelButton();
  }

  static Future<void> _defaultHideChannelButton() async {
    await ChannelTalk.hideChannelButton();
  }
}
