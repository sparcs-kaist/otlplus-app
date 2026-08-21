import 'package:flutter/material.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';

class AuthModel extends ChangeNotifier {
  bool _isLogined = false;
  bool get isLogined => _isLogined;

  final StorageService _storageService;
  final TelemetryCoordinator? _telemetry;

  AuthModel(this._storageService, {TelemetryCoordinator? telemetry})
    : _telemetry = telemetry {
    DioProvider.configureSessionExpiredHandler(_handleRejectedSession);
  }

  void setLoggedIn(bool loggedIn) {
    if (_isLogined != loggedIn) {
      _isLogined = loggedIn;
      notifyListeners();
    }
  }

  Future<void> _handleRejectedSession() async {
    if (!await _storageService.hasTokens()) {
      setLoggedIn(false);
    }
  }

  Future<void> logout() async {
    try {
      await _storageService.deleteTokens();
    } catch (error, stackTrace) {
      await _telemetry?.recordNonFatal(error, stackTrace, operation: 'logout');
      rethrow;
    }
    setLoggedIn(false);
  }
}
