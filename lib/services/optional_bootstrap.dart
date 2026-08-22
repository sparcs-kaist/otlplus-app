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
    Future<bool?> Function({String? memberHash})? channelTalkBoot,
    Future<void> Function(String token)? initPushToken,
    Future<void> Function()? showChannelButton,
    bool? isIOS,
    this.tokenTimeout = const Duration(seconds: 10),
    this.bootTimeout = const Duration(seconds: 10),
  }) : requestPermission = requestPermission ?? _requestPermission,
       getAPNSToken = getAPNSToken ?? _getAPNSToken,
       getToken = getToken ?? _getToken,
       channelTalkBoot = channelTalkBoot ?? _channelTalkBoot,
       initPushToken = initPushToken ?? _initPushToken,
       showChannelButton = showChannelButton ?? _showChannelButton,
       isIOS = isIOS ?? (!kIsWeb && Platform.isIOS);

  final Future<void> Function() requestPermission;
  final Future<String?> Function() getAPNSToken;
  final Future<String?> Function() getToken;
  final Future<bool?> Function({String? memberHash}) channelTalkBoot;
  final Future<void> Function(String token) initPushToken;
  final Future<void> Function() showChannelButton;
  final Future<void> Function(Object error, StackTrace stack) recordNonFatal;
  final bool isIOS;
  final Duration tokenTimeout;
  final Duration bootTimeout;

  Future<void> run() async {
    String? token;

    try {
      await requestPermission();
      if (isIOS) {
        final apnsToken = await getAPNSToken();
        if (apnsToken != null) {
          token = await getToken().timeout(tokenTimeout, onTimeout: () => null);
        }
      } else {
        token = await getToken().timeout(tokenTimeout, onTimeout: () => null);
      }
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
    }

    try {
      final booted = await channelTalkBoot(
        memberHash: token,
      ).timeout(bootTimeout);
      if (booted != true) return;

      if (token != null && token.isNotEmpty) {
        await initPushToken(token);
      }
      await showChannelButton();
    } catch (error, stack) {
      await _recordNonFatalSafely(error, stack);
    }
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
