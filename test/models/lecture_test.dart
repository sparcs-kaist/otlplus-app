import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otlplus/constants/url.dart';

import 'package:otlplus/models/lecture.dart';
import 'package:test/test.dart';

void main() {
  group('check typeIdx', () {
    late Map<String, String> params;

    setUpAll(() async {
      final response = await http.get(
        Uri.https(BASE_AUTHORITY, API_SEMESTER_URL, {
          'order[0]': 'year',
          'order[1]': 'semester',
        }),
      );
      final List<dynamic> body = json.decode(response.body);
      final String year = body[body.length - 1]['year'].toString();
      final String semester = body[body.length - 1]['semester'].toString();
      params = {
        'year': year,
        'semester': semester,
        'keyword': '',
        'department': 'ALL',
        'level': 'ALL',
        'order': 'old_code',
        'limit': '1',
      };
    });

    test('BR type index should be 0', () async {
      final url = Uri.https(
        BASE_AUTHORITY,
        API_LECTURE_URL,
        params..addAll({'type': 'BR'}),
      ).toString();
      final response = await http.get(Uri.parse(url));
      final lectures = json.decode(response.body);
      assert(lectures.isNotEmpty);
      for (Map<String, dynamic> l in lectures) {
        final Lecture lecture = Lecture.fromJson(l);
        expect(lecture.typeIdx, 0);
      }
    });

    test('BE type index should be 1', () async {
      final url = Uri.https(
        BASE_AUTHORITY,
        API_LECTURE_URL,
        params..addAll({'type': 'BE'}),
      ).toString();
      final response = await http.get(Uri.parse(url));
      final lectures = json.decode(response.body);
      assert(lectures.isNotEmpty);
      for (Map<String, dynamic> l in lectures) {
        final Lecture lecture = Lecture.fromJson(l);
        expect(lecture.typeIdx, 1);
      }
    });

    test('MR type index should be 2', () async {
      final url = Uri.https(
        BASE_AUTHORITY,
        API_LECTURE_URL,
        params..addAll({'type': 'MR'}),
      ).toString();
      final response = await http.get(Uri.parse(url));
      final lectures = json.decode(response.body);
      assert(lectures.isNotEmpty);
      for (Map<String, dynamic> l in lectures) {
        final Lecture lecture = Lecture.fromJson(l);
        expect(lecture.typeIdx, 2);
      }
    });

    test('ME type index should be 3', () async {
      final url = Uri.https(
        BASE_AUTHORITY,
        API_LECTURE_URL,
        params..addAll({'type': 'ME'}),
      ).toString();
      final response = await http.get(Uri.parse(url));
      final lectures = json.decode(response.body);
      assert(lectures.isNotEmpty);
      for (Map<String, dynamic> l in lectures) {
        final Lecture lecture = Lecture.fromJson(l);
        expect(lecture.typeIdx, 3);
      }
    });

    test('HSE type index should be 4', () async {
      final url = Uri.https(
        BASE_AUTHORITY,
        API_LECTURE_URL,
        params..addAll({'type': 'HSE'}),
      ).toString();
      final response = await http.get(Uri.parse(url));
      final lectures = json.decode(response.body);
      print(url);
      // 2024년 가을학기부터 HSE 강의 없음
      // 2025년 1월 10일 기준 있음
      assert(!lectures.isEmpty);
      for (Map<String, dynamic> l in lectures) {
        final Lecture lecture = Lecture.fromJson(l);
        expect(lecture.typeIdx, 4);
      }
    });
  });
}
