import 'dart:io';

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
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          if (_navigatorContext != null) {
            try {
              Provider.of<AuthModel>(_navigatorContext!, listen: false).logout();
            } catch (err) {
              print("Error accessing AuthModel for logout: $err");
              await _storageService.deleteTokens();
            }
          } else {
            print("Navigator context not set in DioProvider. Cannot trigger logout via AuthModel.");
            await _storageService.deleteTokens();
          }
          return handler.next(e);
        }
        return handler.next(e);
      },
    ));
  }
}
