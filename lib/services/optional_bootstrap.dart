import 'dart:async';
import 'dart:io';

import 'package:channel_talk_flutter/channel_talk_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class OptionalBootstrap {
  OptionalBootstrap({
    required this.recordNonFatal,
    Future<void> Function()? requestPermission,
    Future<String?> Function()? getAPNSToken,
    Future<String?> Function()? getToken,
    Stream<String> Function()? onTokenRefresh,
    Future<bool?> Function({String? memberHash})? channelTalkBoot,
    Future<void> Function(String token)? initPushToken,
    Future<void> Function()? showChannelButton,
    Future<void> Function(Duration duration)? delay,
    bool? isIOS,
    this.apnsRetryDelay = const Duration(milliseconds: 500),
    this.apnsMaxAttempts = 6,
    this.tokenTimeout = const Duration(seconds: 10),
    this.bootTimeout = const Duration(seconds: 10),
  }) : requestPermission = requestPermission ?? _requestPermission,
       getAPNSToken = getAPNSToken ?? _getAPNSToken,
       getToken = getToken ?? _getToken,
       onTokenRefresh = onTokenRefresh ?? _onTokenRefresh,
       channelTalkBoot = channelTalkBoot ?? _channelTalkBoot,
       initPushToken = initPushToken ?? _initPushToken,
       showChannelButton = showChannelButton ?? _showChannelButton,
       delay = delay ?? _delay,
       isIOS = isIOS ?? (!kIsWeb && Platform.isIOS);

  final Future<void> Function() requestPermission;
  final Future<String?> Function() getAPNSToken;
  final Future<String?> Function() getToken;
  final Stream<String> Function() onTokenRefresh;
  final Future<bool?> Function({String? memberHash}) channelTalkBoot;
  final Future<void> Function(String token) initPushToken;
  final Future<void> Function() showChannelButton;
  final Future<void> Function(Duration duration) delay;
  final Future<void> Function(Object error, StackTrace stack) recordNonFatal;
  final bool isIOS;
  final Duration apnsRetryDelay;
  final int apnsMaxAttempts;
  final Duration tokenTimeout;
  final Duration bootTimeout;

  StreamSubscription<String>? tokenRefreshSubscription;

  Future<void> run() async {
    String? token;

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

    bool? booted;
    try {
      booted = await channelTalkBoot(memberHash: token).timeout(bootTimeout);
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
      return;
    }
    if (booted != true) {
      await _recordNonFatalSafely(
        StateError('ChannelTalk.boot returned false'),
        StackTrace.current,
      );
      return;
    }

    await _subscribeToTokenRefresh();

    if (token != null && token.isNotEmpty) {
      await _initPushTokenSafely(token);
    }

    try {
      await showChannelButton();
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
    }
  }

  Future<void> _subscribeToTokenRefresh() async {
    try {
      tokenRefreshSubscription = onTokenRefresh().listen(
        (token) {
          unawaited(_initPushTokenSafely(token));
        },
        onError: (Object error, StackTrace stack) {
          unawaited(_recordNonFatalSafely(error, stack));
        },
      );
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
    }
  }

  Future<void> _initPushTokenSafely(String token) async {
    try {
      await initPushToken(token);
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
    }
  }

  Future<void> dispose() async {
    await tokenRefreshSubscription?.cancel();
    tokenRefreshSubscription = null;
  }

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

  static Future<void> _showChannelButton() async {
    await ChannelTalk.showChannelButton();
  }
}
