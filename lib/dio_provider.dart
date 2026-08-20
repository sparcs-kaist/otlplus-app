import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';

/// Outcome of a session refresh attempt.
enum SessionRefreshResult {
  /// New tokens were issued and stored.
  success,

  /// The server rejected the session; stored credentials are invalid.
  rejected,

  /// The refresh endpoint could not be reached; credentials may still be
  /// valid, so the session must not be terminated.
  unavailable,
}

class DioProvider {
  static DioProvider? _instance;
  factory DioProvider() => _instance ??= DioProvider._internal();

  late Dio _dio;
  Dio get dio => _dio;

  final StorageService _storageService = StorageService();

  Future<SessionRefreshResult>? _refreshInFlight;

  static TelemetryCoordinator? _telemetry;
  static Future<void> Function()? _onSessionExpired;
  static String Function() _localeSupplier =
      () => PlatformDispatcher.instance.locale.languageCode;

  /// Registers the source used to resolve the locale for each request.
  static void configureLocaleSupplier(String Function() supplier) {
    _localeSupplier = supplier;
  }

  static void configureTelemetry(TelemetryCoordinator telemetry) {
    _telemetry = telemetry;
  }

  /// Registers the callback invoked when the server definitively rejects the
  /// stored session. Replaces the previous navigator-context lookup.
  static void configureSessionExpiredHandler(Future<void> Function() handler) {
    _onSessionExpired = handler;
  }

  DioProvider._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Uri.https(BASE_AUTHORITY).toString() + "/",
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept-Language'] = _localeSupplier();
          final accessToken = await _storageService.getAccessToken();
          final refreshToken = await _storageService.getRefreshToken();

          if (accessToken != null && refreshToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
            options.headers['X-Refresh-Token'] = refreshToken;
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final statusCode = e.response?.statusCode;
          if (e.type != DioExceptionType.cancel &&
              (statusCode == null || statusCode >= 500)) {
            await _telemetry?.recordNonFatal(
              e,
              StackTrace.current,
              operation: 'http_request',
            );
          }
          if (statusCode == 401 &&
              e.requestOptions.extra['sessionRetried'] != true) {
            final result = await refreshSession();
            if (result == SessionRefreshResult.success) {
              try {
                e.requestOptions.extra['sessionRetried'] = true;
                final response = await _dio.fetch(e.requestOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
            if (result == SessionRefreshResult.rejected) {
              await _expireSession();
            }
            // On [SessionRefreshResult.unavailable] the session is kept: the
            // failure was transient and the next request retries naturally.
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Refreshes the stored session, sharing one in-flight attempt between the
  /// cold-start path and any number of concurrent 401 responses.
  Future<SessionRefreshResult> refreshSession() {
    return _refreshInFlight ??= _refreshToken().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> _expireSession() async {
    final handler = _onSessionExpired;
    if (handler != null) {
      try {
        await handler();
        return;
      } catch (error, stackTrace) {
        await _telemetry?.recordNonFatal(
          error,
          stackTrace,
          operation: 'automatic_logout',
        );
      }
    }
    await _storageService.deleteTokens();
  }

  Future<SessionRefreshResult> _refreshToken() async {
    final String? refreshToken;
    try {
      refreshToken = await _storageService.getRefreshToken();
    } catch (error, stackTrace) {
      await _telemetry?.recordNonFatal(
        error,
        stackTrace,
        operation: 'refresh_session',
      );
      return SessionRefreshResult.unavailable;
    }
    if (refreshToken == null) {
      return SessionRefreshResult.rejected;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
        headers: {'Accept-Language': _localeSupplier()},
      ),
    );
    try {
      final response = await refreshDio.post(
        SESSION_REFRESH_URL,
        data: {'token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];

        if (newAccessToken != null && newRefreshToken != null) {
          await _storageService.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          return SessionRefreshResult.success;
        }
      }
      return SessionRefreshResult.rejected;
    } on DioException catch (error, stackTrace) {
      final status = error.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        return SessionRefreshResult.rejected;
      }
      await _telemetry?.recordNonFatal(
        error,
        stackTrace,
        operation: 'refresh_session',
      );
      return SessionRefreshResult.unavailable;
    } catch (error, stackTrace) {
      await _telemetry?.recordNonFatal(
        error,
        stackTrace,
        operation: 'refresh_session',
      );
      return SessionRefreshResult.unavailable;
    }
  }
}
