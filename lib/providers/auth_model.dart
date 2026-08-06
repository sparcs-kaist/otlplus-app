import 'package:flutter/material.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class AuthModel extends ChangeNotifier {
  bool _isLogined = false;
  bool get isLogined => _isLogined;

  final StorageService _storageService;
  final TelemetryCoordinator? _telemetry;

  AuthModel(this._storageService, {TelemetryCoordinator? telemetry})
    : _telemetry = telemetry {
    _checkInitialLoginState();
  }

  Future<void> _checkInitialLoginState() async {
    _isLogined = await _storageService.hasTokens();
    notifyListeners();
  }

  void setLoggedIn(bool loggedIn) {
    if (_isLogined != loggedIn) {
      _isLogined = loggedIn;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      final cookieManager = WebviewCookieManager();
      await cookieManager.clearCookies();
      await _storageService.deleteTokens();
      _isLogined = false;
      notifyListeners();
    } catch (error, stackTrace) {
      await _telemetry?.recordNonFatal(
        error,
        stackTrace,
        operation: 'logout',
      );
    }
  }
}
