import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html_parser;

class SsoTokenPair {
  final String accessToken;
  final String refreshToken;

  const SsoTokenPair({required this.accessToken, required this.refreshToken});
}

class SsoLoginException implements Exception {
  final String stage;
  final String message;

  const SsoLoginException(this.stage, this.message);

  @override
  String toString() => 'SsoLoginException($stage): $message';
}

String sanitizeUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme.isEmpty) {
    return 'invalid-uri';
  }
  final path = uri.path.isEmpty ? '/' : uri.path;
  return '${uri.scheme}://${uri.host}$path';
}

class SsoClient {
  SsoClient({HttpClientAdapter? adapter})
    : _cookieJar = CookieJar(),
      _dio = Dio(
        BaseOptions(
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: <String, Object>{HttpHeaders.userAgentHeader: 'otl-app'},
        ),
      ) {
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
    }
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static final Uri _startUri = Uri.parse(
    'https://otl.kaist.ac.kr/session/login/',
  );
  static const Set<String> _allowedHosts = <String>{
    'otl.kaist.ac.kr',
    'sparcssso.kaist.ac.kr',
  };
  static const int _maximumRedirectHops = 12;
  static const Duration _totalBudget = Duration(seconds: 60);

  final CookieJar _cookieJar;
  final Dio _dio;

  Future<SsoTokenPair> login({
    required String email,
    required String password,
  }) async {
    final stopwatch = Stopwatch()..start();
    var request = _RequestState.get(_startUri);
    var redirectHops = 0;

    while (true) {
      _ensureWithinBudget(stopwatch);
      final response = await _sendWithRetry(request, stopwatch);
      _ensureWithinBudget(stopwatch);

      final location = response.headers.value(HttpHeaders.locationHeader);
      final body = response.data is String ? response.data! as String : '';

      if (request.isCredentialPost && response.statusCode == HttpStatus.ok) {
        if (body.contains('alert-invalid-account') || location == null) {
          throw const SsoLoginException(
            'credential-post',
            'SPARCS SSO rejected the credentials or the login page markup changed',
          );
        }
      }

      if (location != null && location.isNotEmpty) {
        final target = _resolveLocation(request.uri, location);
        redirectHops += 1;
        if (redirectHops > _maximumRedirectHops) {
          throw SsoLoginException(
            'redirect-cap',
            'Redirect cap exceeded at ${sanitizeUri(target.toString())}',
          );
        }

        if (_isTerminalUri(target)) {
          return _extractTokens(target);
        }
        _ensureAllowedHost(target);
        request = request.followRedirect(response.statusCode, target);
        continue;
      }

      if ((response.statusCode == HttpStatus.ok ||
              response.statusCode == HttpStatus.created) &&
          body.contains('<form')) {
        if (request.isCredentialPost) {
          // The server bounced us back to the login form after submitting
          // credentials: an invalid-account rejection, not a fresh flow.
          throw const SsoLoginException(
            'credential-post',
            'SPARCS SSO rejected the credentials or the login page markup changed',
          );
        }
        request = _buildCredentialPost(
          pageUri: request.uri,
          body: body,
          email: email,
          password: password,
        );
        continue;
      }

      throw SsoLoginException(
        'form-parse',
        'No recognizable SPARCS SSO login form at '
            '${sanitizeUri(request.uri.toString())}',
      );
    }
  }

  Future<Response<Object?>> _sendWithRetry(
    _RequestState request,
    Stopwatch stopwatch,
  ) async {
    for (var attempt = 0; attempt < 2; attempt += 1) {
      final remaining = _remainingBudget(stopwatch);
      if (remaining <= Duration.zero) {
        throw SsoLoginException(
          'timeout',
          'SSO login timed out at ${sanitizeUri(request.uri.toString())}',
        );
      }

      try {
        return await _dio
            .requestUri<Object?>(
              request.uri,
              data: request.body,
              options: Options(
                method: request.method,
                headers: request.headers,
                contentType: request.contentType,
              ),
            )
            .timeout(remaining);
      } on TimeoutException {
        throw SsoLoginException(
          'timeout',
          'SSO login timed out at ${sanitizeUri(request.uri.toString())}',
        );
      } on DioException catch (error) {
        final retryable = _isRetryableTransportError(error);
        if (retryable && attempt == 0) {
          continue;
        }
        throw SsoLoginException(
          'transport',
          'Request failed at ${sanitizeUri(request.uri.toString())}',
        );
      }
    }

    throw SsoLoginException(
      'transport',
      'Request failed at ${sanitizeUri(request.uri.toString())}',
    );
  }

  _RequestState _buildCredentialPost({
    required Uri pageUri,
    required String body,
    required String email,
    required String password,
  }) {
    final document = html_parser.parse(body);
    final forms = document.querySelectorAll('form[action]');
    final form = forms.where((element) {
      return element.attributes['action'] == '/account/login/';
    }).firstOrNull;
    if (form == null) {
      throw SsoLoginException(
        'form-parse',
        'No recognizable SPARCS SSO login form at '
            '${sanitizeUri(pageUri.toString())}',
      );
    }

    final action = form.attributes['action'];
    if (action == null || action.isEmpty) {
      throw SsoLoginException(
        'form-parse',
        'SPARCS SSO login form has no action at '
            '${sanitizeUri(pageUri.toString())}',
      );
    }

    final fields = <String, String>{};
    for (final input in form.querySelectorAll('input')) {
      if (input.attributes['type']?.toLowerCase() != 'hidden') {
        continue;
      }
      final name = input.attributes['name'];
      if (name == null || name.isEmpty) {
        continue;
      }
      fields[name] = input.attributes['value'] ?? '';
    }
    fields['email'] = email;
    fields['password'] = password;

    return _RequestState(
      uri: pageUri.resolve(action),
      method: 'POST',
      body: fields,
      headers: <String, Object>{HttpHeaders.refererHeader: pageUri.toString()},
      contentType: Headers.formUrlEncodedContentType,
      isCredentialPost: true,
    );
  }

  static Uri _resolveLocation(Uri currentUri, String location) {
    try {
      return currentUri.resolve(location);
    } on FormatException {
      throw const SsoLoginException(
        'redirect-parse',
        'SSO returned an invalid redirect location',
      );
    }
  }

  static void _ensureAllowedHost(Uri uri) {
    if (!_allowedHosts.contains(uri.host)) {
      throw SsoLoginException(
        'disallowed-host',
        'Redirected to disallowed host ${sanitizeUri(uri.toString())}',
      );
    }
  }

  static bool _isTerminalUri(Uri uri) {
    return uri.scheme == 'org.sparcs.otl' && uri.host == 'login';
  }

  static SsoTokenPair _extractTokens(Uri uri) {
    final accessToken = uri.queryParameters['accessToken'];
    final refreshToken = uri.queryParameters['refreshToken'];
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw SsoLoginException(
        'token-extract',
        'Missing SSO tokens in ${sanitizeUri(uri.toString())}',
      );
    }
    return SsoTokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }

  static bool _isRetryableTransportError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout;
  }

  static Duration _remainingBudget(Stopwatch stopwatch) {
    return _totalBudget - stopwatch.elapsed;
  }

  static void _ensureWithinBudget(Stopwatch stopwatch) {
    if (stopwatch.elapsed >= _totalBudget) {
      throw const SsoLoginException(
        'timeout',
        'SSO login exceeded the 60 second time budget',
      );
    }
  }
}

class _RequestState {
  const _RequestState({
    required this.uri,
    required this.method,
    this.body,
    this.headers,
    this.contentType,
    this.isCredentialPost = false,
  });

  factory _RequestState.get(Uri uri, {bool isCredentialPost = false}) {
    return _RequestState(
      uri: uri,
      method: 'GET',
      isCredentialPost: isCredentialPost,
    );
  }

  final Uri uri;
  final String method;
  final Object? body;
  final Map<String, Object>? headers;
  final String? contentType;
  final bool isCredentialPost;

  _RequestState followRedirect(int? statusCode, Uri target) {
    // 301/302/303 downgrade to a plain GET (the OAuth chain never relies on
    // method preservation); 307/308 keep method and body verbatim.
    if (statusCode == HttpStatus.movedPermanently ||
        statusCode == HttpStatus.found ||
        statusCode == HttpStatus.seeOther) {
      return _RequestState.get(target, isCredentialPost: isCredentialPost);
    }
    return _RequestState(
      uri: target,
      method: method,
      body: body,
      headers: headers,
      contentType: contentType,
      isCredentialPost: isCredentialPost,
    );
  }
}
