import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_widgetkit/flutter_widgetkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  /// App group shared with the iOS widget extension.
  static const String _iosAppGroup = 'group.org.sparcs.otl';

  // Save tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _syncWidgetTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  // Delete tokens
  Future<void> deleteTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _syncWidgetTokens(accessToken: null, refreshToken: null);
  }

  // Check if tokens exist
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Mirrors the session into widget-readable storage so home screen widgets
  /// stay signed in after a token refresh, and sign out on logout.
  Future<void> _syncWidgetTokens({
    required String? accessToken,
    required String? refreshToken,
  }) async {
    try {
      if (Platform.isIOS) {
        WidgetKit.setItem('accessToken', accessToken ?? '', _iosAppGroup);
        WidgetKit.setItem('refreshToken', refreshToken ?? '', _iosAppGroup);
        WidgetKit.reloadAllTimelines();
      } else if (Platform.isAndroid) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken ?? '');
        await prefs.setString('refresh_token', refreshToken ?? '');
      }
    } catch (error) {
      // Widget storage is best-effort; never block the auth flow on it.
      debugPrint('Widget token sync failed: $error');
    }
  }
}
