import 'dart:convert';
import 'dart:io';

import 'package:otlplus/models/lecture.dart';
import 'package:test/test.dart';

void main() {
  group('check typeIdx', () {
    late Map<String, dynamic> lectureJson;

    setUpAll(() async {
      final fixture =
          jsonDecode(
                await File(
                  'test/fixtures/v2/lectures_search.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      lectureJson = Map<String, dynamic>.from(
        fixture['courses'][0]['lectures'][0] as Map<String, dynamic>,
      );
    });

    const localizedTypes = ['기초필수', '기초선택', '전공필수', '전공선택', '인문사회선택'];
    for (var index = 0; index < TYPES.length; index++) {
      test('${TYPES[index]} and localized type map to $index', () {
        for (final type in [TYPES[index], localizedTypes[index]]) {
          final lecture = Lecture.fromV2Json(
            {...lectureJson, 'type': type},
            year: 2026,
            semester: 1,
          );
          expect(lecture.typeIdx, index);
        }
      });
    }

    test(
      'v2 averages preserve score availability for shared lecture details',
      () {
        final lecture = Lecture.fromV2Json(
          {
            ...lectureJson,
            'averageGrade': 4,
            'averageLoad': 3,
            'averageSpeech': 2,
          },
          year: 2026,
          semester: 1,
        );
        expect(lecture.reviewTotalWeight, greaterThan(0));
      },
    );

    test('other types map to ETC', () {
      final lecture = Lecture.fromV2Json(
        {...lectureJson, 'type': '선택(석/박사)'},
        year: 2026,
        semester: 1,
      );
      expect(lecture.typeIdx, 5);
    });
  });
}
