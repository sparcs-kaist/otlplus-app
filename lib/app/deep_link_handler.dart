import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';

class DeepLinkHandler {
  DeepLinkHandler({
    required StorageService storageService,
    required AuthModel Function() authModel,
    required bool Function() isMounted,
    required bool Function() isLoading,
    required VoidCallback onLoaded,
    required TelemetryCoordinator telemetryCoordinator,
    Stream<Uri>? uriLinkStreamOverride,
    Future<void> Function(Object error, StackTrace stack)?
    recordNonFatalOverride,
  }) : _storageService = storageService,
       _authModel = authModel,
       _isMounted = isMounted,
       _isLoading = isLoading,
       _onLoaded = onLoaded,
       _telemetryCoordinator = telemetryCoordinator,
       _uriLinkStreamOverride = uriLinkStreamOverride,
       _recordNonFatalOverride = recordNonFatalOverride;

  final _appLinks = AppLinks();
  final StorageService _storageService;
  final AuthModel Function() _authModel;
  final bool Function() _isMounted;
  final bool Function() _isLoading;
  final VoidCallback _onLoaded;
  final TelemetryCoordinator _telemetryCoordinator;
  final Stream<Uri>? _uriLinkStreamOverride;
  final Future<void> Function(Object error, StackTrace stack)?
  _recordNonFatalOverride;
  StreamSubscription<Uri>? _linkSubscription;

  void initialize() {
    final uriLinkStream = _uriLinkStreamOverride ?? _appLinks.uriLinkStream;
    _linkSubscription = uriLinkStream.listen(
      (uri) {
        if (uri.host == 'login' && uri.path == '/') {
          final accessToken = uri.queryParameters['accessToken'];
          final refreshToken = uri.queryParameters['refreshToken'];

          if (accessToken != null && refreshToken != null) {
            unawaited(_handleLoginTokensSafely(accessToken, refreshToken));
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        unawaited(
          _recordDeepLinkNonFatalSafely(
            error,
            stackTrace,
            operation: 'deep_link_stream',
          ),
        );
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  Future<void> _handleLoginTokensSafely(
    String accessToken,
    String refreshToken,
  ) async {
    try {
      await _handleLoginTokens(accessToken, refreshToken);
    } catch (error, stackTrace) {
      await _recordDeepLinkNonFatalSafely(
        error,
        stackTrace,
        operation: 'deep_link_login',
      );
    }
  }

  Future<void> _handleLoginTokens(
    String accessToken,
    String refreshToken,
  ) async {
    final auth = _authModel();
    await _storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    auth.setLoggedIn(true);
    if (!_isMounted()) return;
    if (_isLoading()) {
      _onLoaded();
    }
  }

  Future<void> _recordDeepLinkNonFatalSafely(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) async {
    try {
      final recordNonFatal = _recordNonFatalOverride;
      if (recordNonFatal != null) {
        await recordNonFatal(error, stackTrace);
      } else {
        await _telemetryCoordinator.recordNonFatal(
          error,
          stackTrace,
          operation: operation,
        );
      }
    } catch (_) {
      // Intentional: deep-link error reporting must never escape to the app zone.
    }
  }
}
