import 'package:dio/dio.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:flutter/material.dart';

class DioProvider {
  static DioProvider? _instance;
  factory DioProvider() => _instance ??= DioProvider._internal();

  late Dio _dio;
  Dio get dio => _dio;

  final StorageService _storageService = StorageService();

  bool _isRefreshingToken = false;

  static BuildContext? _navigatorContext;
  static BuildContext? get navigatorContext => _navigatorContext;

  static void setNavigatorContext(BuildContext context) {
    _navigatorContext = context;
  }

  DioProvider._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: Uri.https(BASE_AUTHORITY).toString() + "/",
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await _storageService.getAccessToken();
        final refreshToken = await _storageService.getRefreshToken();

        if (accessToken != null && refreshToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
          options.headers['X-Refresh-Token'] = refreshToken;
        }
        return handler.next(options);
      },
      // 기존 구현에서는 401 상태가 오면 바로 로그아웃을 호출하여
      // 토큰이 만료된 경우에도 자동 로그인 상태가 해제되는 문제가 있었다.
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          if (!_isRefreshingToken) {
            _isRefreshingToken = true;
            final refreshed = await _refreshToken();
            _isRefreshingToken = false;
            if (refreshed) {
              try {
                final response = await _dio.fetch(e.requestOptions);
                return handler.resolve(response);
              } catch (err) {
                // If retry fails, fall through to logout
              }
            }
          }

          if (_navigatorContext != null) {
            try {
              Provider.of<AuthModel>(_navigatorContext!, listen: false)
                  .logout();
            } catch (err) {
              print("Error accessing AuthModel for logout: $err");
              await _storageService.deleteTokens();
            }
          } else {
            print(
                "Navigator context not set in DioProvider. Cannot trigger logout via AuthModel.");
            await _storageService.deleteTokens();
          }
          return handler.next(e);
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null) {
      return false;
    }

    final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
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
              accessToken: newAccessToken, refreshToken: newRefreshToken);
          return true;
        }
      }
    } catch (e) {
      print('Error refreshing token in DioProvider: $e');
    }
    return false;
  }
}
