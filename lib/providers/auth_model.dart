import 'package:flutter/material.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class AuthModel extends ChangeNotifier {
  bool _isLogined = false;
  bool get isLogined => _isLogined;

  Future<void> authenticate(String url) async {
    final cookieManager = WebviewCookieManager();
    try {
      final cookies = await cookieManager.getCookies(url);
      DioProvider().authenticate(cookies);
      _isLogined = true;
      notifyListeners();
    } catch (exception) {
      await logout();
      throw exception;
    }
  }

  Future<void> logout() async {
    try {
      final cookieManager = WebviewCookieManager();
      // cookieManager.removeCookie(url);
      await cookieManager.clearCookies();
      DioProvider().logout();
      _isLogined = false;
      notifyListeners();
    } catch (exception) {
      print(exception);
    }
  }
}
