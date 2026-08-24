import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/sso_client.dart';

const _startUrl = 'https://otl.kaist.ac.kr/session/login/';
const _ssoRequireUrl =
    'https://sparcssso.kaist.ac.kr/api/v2/token/require/'
    '?client_id=otlplus&state=abc&preferred_url=https%3A%2F%2F'
    'otl.kaist.ac.kr%2Fsession%2Flogin%2Fcallback%2F';
const _loginPageLocation =
    '/account/login/?next=/api/v2/token/require/'
    '%3Fclient_id%3Dotlplus%26state%3Dabc';
const _loginPageUrl = 'https://sparcssso.kaist.ac.kr$_loginPageLocation';
const _fixtureNext =
    '/api/v2/token/require/%3Fclient_id%3Dotlplus%26state%3Dfixture-state'
    '%26preferred_url%3Dhttps%253A%252F%252Fotl.kaist.ac.kr%252Fsession'
    '%252Flogin%252Fcallback%252F';

class RecordedRequest {
  const RecordedRequest({
    required this.method,
    required this.uri,
    required this.headers,
    required this.body,
  });

  final String method;
  final Uri uri;
  final Map<String, Object?> headers;
  final String body;

  String? header(String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) {
        final value = entry.value;
        if (value is Iterable<Object?>) {
          return value.join(', ');
        }
        return value?.toString();
      }
    }
    return null;
  }
}

typedef ScriptedStep = FutureOr<ResponseBody> Function(RecordedRequest request);

class ScriptedHttpClientAdapter implements HttpClientAdapter {
  ScriptedHttpClientAdapter(List<ScriptedStep> steps)
    : _steps = List<ScriptedStep>.from(steps);

  final List<ScriptedStep> _steps;
  final List<RecordedRequest> requests = <RecordedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_steps.isEmpty) {
      throw StateError('Unexpected request: ${options.method} ${options.uri}');
    }

    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    final request = RecordedRequest(
      method: options.method,
      uri: options.uri,
      headers: Map<String, Object?>.from(options.headers),
      body: utf8.decode(bytes),
    );
    requests.add(request);
    return await _steps.removeAt(0)(request);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _redirect(
  String location, {
  int statusCode = HttpStatus.found,
  List<String> setCookies = const <String>[],
}) {
  return ResponseBody.fromString(
    '',
    statusCode,
    headers: <String, List<String>>{
      HttpHeaders.locationHeader: <String>[location],
      if (setCookies.isNotEmpty)
        HttpHeaders.setCookieHeader: List<String>.from(setCookies),
    },
  );
}

ResponseBody _html(String body) {
  return ResponseBody.fromString(
    body,
    HttpStatus.ok,
    headers: <String, List<String>>{
      HttpHeaders.contentTypeHeader: <String>['text/html; charset=utf-8'],
    },
  );
}

Future<String> _fixture(String name) {
  return File('test/fixtures/sso/$name').readAsString();
}

void main() {
  test('completes the sso handshake and returns the token pair', () async {
    final loginForm = await _fixture('login_form.html');
    const email = 'fixture@example.com';
    const password = 'fixture-password';
    final adapter = ScriptedHttpClientAdapter(<ScriptedStep>[
      (request) {
        expect(request.method, 'GET');
        expect(request.uri.toString(), _startUrl);
        return _redirect(
          _ssoRequireUrl,
          setCookies: const <String>['csrftoken=otl-csrf; Path=/'],
        );
      },
      (request) {
        expect(request.method, 'GET');
        expect(request.uri.toString(), _ssoRequireUrl);
        return _redirect(
          _loginPageLocation,
          setCookies: const <String>[
            'sessionid=s1; Path=/',
            'csrftoken=sparcs-csrf; Path=/',
          ],
        );
      },
      (request) {
        expect(request.method, 'GET');
        expect(request.uri.toString(), _loginPageUrl);
        return _html(loginForm);
      },
      (request) {
        expect(request.method, 'POST');
        expect(
          request.uri.toString(),
          'https://sparcssso.kaist.ac.kr/account/login/',
        );
        expect(
          request.header(HttpHeaders.contentTypeHeader),
          startsWith(Headers.formUrlEncodedContentType),
        );
        expect(request.header(HttpHeaders.refererHeader), _loginPageUrl);
        expect(request.header('X-CSRFToken'), isNull);

        final form = Uri.splitQueryString(request.body);
        expect(form['email'], email);
        expect(form['password'], password);
        expect(form['csrfmiddlewaretoken'], 'fixture-csrf-token-123');
        expect(form['next'], _fixtureNext);
        expect(
          request.body,
          contains(
            'next=%2Fapi%2Fv2%2Ftoken%2Frequire%2F%253Fclient_id%253Dotlplus',
          ),
        );

        final cookie = request.header(HttpHeaders.cookieHeader) ?? '';
        expect(
          cookie.contains('sessionid=s1') ||
              cookie.contains('csrftoken=sparcs-csrf'),
          isTrue,
        );
        return _redirect('/api/v2/token/require/?client_id=otlplus&state=abc');
      },
      (request) {
        expect(request.method, 'GET');
        expect(
          request.uri.toString(),
          'https://sparcssso.kaist.ac.kr/api/v2/token/require/'
          '?client_id=otlplus&state=abc',
        );
        return _redirect(
          'https://otl.kaist.ac.kr/session/login/callback/'
          '?code=xyz&state=abc',
        );
      },
      (request) {
        expect(request.method, 'GET');
        expect(
          request.uri.toString(),
          'https://otl.kaist.ac.kr/session/login/callback/'
          '?code=xyz&state=abc',
        );
        return _redirect(
          'org.sparcs.otl://login/'
          '?accessToken=AT-xyz&refreshToken=RT-xyz',
        );
      },
    ]);

    final tokens = await SsoClient(
      adapter: adapter,
    ).login(email: email, password: password);

    expect(tokens.accessToken, 'AT-xyz');
    expect(tokens.refreshToken, 'RT-xyz');
    expect(adapter.requests, hasLength(6));
  });

  test('invalid credentials fail with a sanitized diagnosable error', () async {
    final loginForm = await _fixture('login_form.html');
    final invalidLogin = await _fixture('invalid_login.html');
    const email = 'invalid-fixture@example.com';
    const password = 'super-secret-fixture-password';
    final adapter = ScriptedHttpClientAdapter(<ScriptedStep>[
      (_) => _redirect(_ssoRequireUrl),
      (_) => _redirect(
        _loginPageLocation,
        setCookies: const <String>[
          'sessionid=s1; Path=/',
          'csrftoken=sparcs-csrf; Path=/',
        ],
      ),
      (_) => _html(loginForm),
      (_) => _html(invalidLogin),
    ]);

    Object? thrown;
    try {
      await SsoClient(adapter: adapter).login(email: email, password: password);
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<SsoLoginException>());
    final exception = thrown! as SsoLoginException;
    expect(exception.stage, 'credential-post');
    expect(exception.message, contains('invalid credentials'));
    expect(exception.message, isNot(contains(password)));
    expect(exception.message, isNot(contains(email)));
  });

  test('stops after the redirect cap', () async {
    final adapter = ScriptedHttpClientAdapter(
      List<ScriptedStep>.generate(13, (index) {
        return (_) => _redirect(
          index.isEven
              ? 'https://sparcssso.kaist.ac.kr/loop/$index?state=secret-$index'
              : 'https://otl.kaist.ac.kr/loop/$index?state=secret-$index',
        );
      }),
    );

    await expectLater(
      SsoClient(
        adapter: adapter,
      ).login(email: 'fixture@example.com', password: 'fixture-password'),
      throwsA(
        isA<SsoLoginException>().having(
          (exception) => exception.stage,
          'stage',
          'redirect-cap',
        ),
      ),
    );
  });

  test('rejects redirects to unlisted hosts', () async {
    final adapter = ScriptedHttpClientAdapter(<ScriptedStep>[
      (_) => _redirect('https://evil.example.com/x?token=must-not-leak'),
    ]);

    Object? thrown;
    try {
      await SsoClient(
        adapter: adapter,
      ).login(email: 'fixture@example.com', password: 'fixture-password');
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<SsoLoginException>());
    final exception = thrown! as SsoLoginException;
    expect(exception.stage, 'disallowed-host');
    expect(exception.message, contains('evil.example.com'));
    expect(exception.message, isNot(contains('?')));
    expect(exception.message, isNot(contains('must-not-leak')));
  });

  test('extracts nothing when token query params are missing', () async {
    final adapter = ScriptedHttpClientAdapter(<ScriptedStep>[
      (_) => _redirect('org.sparcs.otl://login/?accessToken=only'),
    ]);

    await expectLater(
      SsoClient(
        adapter: adapter,
      ).login(email: 'fixture@example.com', password: 'fixture-password'),
      throwsA(
        isA<SsoLoginException>().having(
          (exception) => exception.stage,
          'stage',
          'token-extract',
        ),
      ),
    );
  });

  test('unknown page fingerprints redact long tokens', () async {
    final adapter = ScriptedHttpClientAdapter(<ScriptedStep>[
      (_) => ResponseBody.fromString(
        '{"accessToken":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ999999",'
        '"refreshToken":"zzzz9999yyyy8888xxxx7777"}',
        HttpStatus.ok,
        headers: <String, List<String>>{
          HttpHeaders.contentTypeHeader: <String>['application/json'],
        },
      ),
    ]);

    Object? thrown;
    try {
      await SsoClient(
        adapter: adapter,
      ).login(email: 'fixture@example.com', password: 'fixture-password');
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<SsoLoginException>());
    final exception = thrown! as SsoLoginException;
    expect(exception.stage, 'form-parse');
    expect(exception.message, contains('accessToken-key=true'));
    expect(
      exception.message,
      isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ999999')),
    );
    expect(exception.message, isNot(contains('zzzz9999yyyy8888xxxx7777')));
    expect(exception.message, contains('<redacted>'));
  });

  test('follows a meta-refresh page redirect to the custom scheme', () async {
    final loginForm = await _fixture('login_form.html');
    final successPage = await _fixture('login_success.html');
    var sawSuccessPage = false;
    final adapter = ScriptedHttpClientAdapter(<ScriptedStep>[
      (_) => _redirect(_ssoRequireUrl),
      (_) => _redirect(_loginPageLocation),
      (_) => _html(loginForm),
      (request) {
        expect(request.method, 'POST');
        return _redirect('https://otl.kaist.ac.kr/login/success?next=%2F');
      },
      (request) async {
        sawSuccessPage = true;
        expect(request.uri.host, 'otl.kaist.ac.kr');
        return _html(successPage);
      },
    ]);

    final tokens = await SsoClient(
      adapter: adapter,
    ).login(email: 'fixture@example.com', password: 'fixture-password');

    expect(sawSuccessPage, isTrue);
    expect(tokens.accessToken, 'PG-AT');
    expect(tokens.refreshToken, 'PG-RT');
  });

  test('301 redirects downgrade the credential post to a plain GET', () async {
    final loginForm = await _fixture('login_form.html');
    var sawPostRedirect = false;
    final adapter = ScriptedHttpClientAdapter(<ScriptedStep>[
      (_) => _redirect(_ssoRequireUrl),
      (_) => _redirect(_loginPageLocation),
      (_) => _html(loginForm),
      (request) {
        expect(request.method, 'POST');
        return _redirect(
          '/api/v2/token/require/?client_id=otlplus&state=abc',
          statusCode: HttpStatus.movedPermanently,
        );
      },
      (request) async {
        sawPostRedirect = true;
        expect(request.method, 'GET');
        expect(request.body, isEmpty);
        return _redirect(
          'org.sparcs.otl://login/'
          '?accessToken=AT-301&refreshToken=RT-301',
        );
      },
    ]);

    final tokens = await SsoClient(
      adapter: adapter,
    ).login(email: 'fixture@example.com', password: 'fixture-password');

    expect(sawPostRedirect, isTrue);
    expect(tokens.accessToken, 'AT-301');
    expect(tokens.refreshToken, 'RT-301');
  });

  test(
    'a redirect back to the login form after submit is a rejection',
    () async {
      final loginForm = await _fixture('login_form.html');
      const password = 'super-secret-fixture-password';
      final adapter = ScriptedHttpClientAdapter(<ScriptedStep>[
        (_) => _redirect(_ssoRequireUrl),
        (_) => _redirect(_loginPageLocation),
        (_) => _html(loginForm),
        // Server bounces back to the login page instead of continuing the
        // OAuth chain: an invalid-account rejection that must not loop.
        (_) => _redirect(_loginPageLocation),
        (_) => _html(loginForm),
      ]);

      Object? thrown;
      try {
        await SsoClient(
          adapter: adapter,
        ).login(email: 'fixture@example.com', password: password);
      } catch (error) {
        thrown = error;
      }

      expect(thrown, isA<SsoLoginException>());
      final exception = thrown! as SsoLoginException;
      expect(exception.stage, 'credential-post');
      expect(exception.message, isNot(contains(password)));
      // The form must not have been submitted twice.
      expect(
        adapter.requests.where((request) => request.method == 'POST'),
        hasLength(1),
      );
    },
  );
}
