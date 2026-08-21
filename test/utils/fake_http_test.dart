import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_http.dart';

void main() {
  test(
    'returns canned JSON for a matched GET and 404 for an unmatched route',
    () async {
      final adapter = FakeHttpAdapter(
        routes: <String, FakeHttpResponse>{
          'GET /api/v2/semesters': const FakeHttpResponse(<String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'year': 2026, 'semester': 1},
            ],
          }),
        },
      );
      final dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = adapter;

      final matched = await dio.get<Object?>('/api/v2/semesters');
      final unmatched = await dio.get<Object?>('/api/v2/missing');

      expect(matched.statusCode, 200);
      expect(matched.data, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'year': 2026, 'semester': 1},
        ],
      });
      expect(unmatched.statusCode, 404);
      expect(unmatched.data, <String, dynamic>{'detail': 'Route not found'});
    },
  );

  test(
    'distinguishes normalized query routes from omitted query parameters',
    () async {
      final adapter = FakeHttpAdapter(
        routes: <String, FakeHttpResponse>{
          'GET /api/v2/reviews': const FakeHttpResponse('omitted'),
          'GET /api/v2/reviews?courseId=1&mode=default': const FakeHttpResponse(
            'default',
          ),
          'GET /api/v2/reviews?courseId=1&mode=liked': const FakeHttpResponse(
            'liked',
          ),
        },
      );
      final dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = adapter;

      final omitted = await dio.get<Object?>('/api/v2/reviews');
      final defaultMode = await dio.get<Object?>(
        '/api/v2/reviews',
        queryParameters: <String, Object?>{'mode': 'default', 'courseId': 1},
      );
      final likedMode = await dio.get<Object?>(
        '/api/v2/reviews',
        queryParameters: <String, Object?>{'courseId': 1, 'mode': 'liked'},
      );

      expect(omitted.data, 'omitted');
      expect(defaultMode.data, 'default');
      expect(likedMode.data, 'liked');
    },
  );
}
