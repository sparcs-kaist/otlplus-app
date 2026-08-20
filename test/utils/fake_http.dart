import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeHttpResponse {
  const FakeHttpResponse(
    this.body, {
    this.statusCode = 200,
    this.headers = const <String, List<String>>{},
  });

  final Object? body;
  final int statusCode;
  final Map<String, List<String>> headers;
}

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter({Map<String, FakeHttpResponse> routes = const {}})
    : _routes = Map<String, FakeHttpResponse>.from(routes);

  final Map<String, FakeHttpResponse> _routes;

  void register(
    String method,
    String path,
    Object? body, {
    int statusCode = 200,
    Map<String, List<String>> headers = const <String, List<String>>{},
  }) {
    _routes[_key(method, path)] = FakeHttpResponse(
      body,
      statusCode: statusCode,
      headers: headers,
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final route = _routes[_key(options.method, options.uri.toString())];
    if (route == null) {
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'detail': 'Route not found'}),
        404,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(route.body),
      route.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        ...route.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}

  static String _key(String method, String uri) {
    final parsed = Uri.parse(uri);
    final query = parsed.queryParametersAll.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final normalizedQuery = query
        .expand((entry) {
          final values = entry.value.toList()..sort();
          return values.map(
            (value) =>
                '${Uri.encodeQueryComponent(entry.key)}='
                '${Uri.encodeQueryComponent(value)}',
          );
        })
        .join('&');
    final suffix = normalizedQuery.isEmpty ? '' : '?$normalizedQuery';
    return '${method.toUpperCase()} ${parsed.path}$suffix';
  }
}
