import 'dart:convert';
import 'dart:io';

import 'package:otlplus/models/timetable.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, dynamic> listFixture;
  late Map<String, dynamic> detailFixture;

  setUpAll(() async {
    listFixture =
        jsonDecode(
              await File(
                'test/fixtures/v2/timetables_list.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    detailFixture =
        jsonDecode(
              await File(
                'test/fixtures/v2/timetable_detail.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
  });

  group('TimetableListItem.fromV2Json', () {
    test('strictly parses the v2 timetable summary fields', () {
      final rawTimetables = listFixture['timetables'] as List<dynamic>;
      final item = TimetableListItem.fromV2Json(
        rawTimetables.single as Map<String, dynamic>,
      );

      expect(item.id, 1);
      expect(item.name, '시간표');
      expect(item.year, 2026);
      expect(item.semester, 3);
      expect(item.timeTableOrder, 0);
    });

    for (final invalidCase in <({String field, Object value})>[
      (field: 'id', value: 0),
      (field: 'name', value: ' '),
      (field: 'year', value: 0),
      (field: 'semester', value: 0),
      (field: 'semester', value: 5),
      (field: 'timeTableOrder', value: -1),
    ]) {
      test('rejects ${invalidCase.field}=${invalidCase.value} as invalid', () {
        final json = <String, dynamic>{
          'id': 1,
          'name': '시간표',
          'year': 2026,
          'semester': 3,
          'timeTableOrder': 0,
          invalidCase.field: invalidCase.value,
        };

        expect(
          () => TimetableListItem.fromV2Json(json),
          throwsA(isA<FormatException>()),
        );
      });
    }

    for (final field in <String>[
      'id',
      'name',
      'year',
      'semester',
      'timeTableOrder',
    ]) {
      test('rejects a missing required $field', () {
        final json = <String, dynamic>{
          'id': 1,
          'name': '시간표',
          'year': 2026,
          'semester': 3,
          'timeTableOrder': 0,
        }..remove(field);

        expect(
          () => TimetableListItem.fromV2Json(json),
          throwsA(isA<TypeError>()),
        );
      });
    }

    for (final entry in <String, Object>{
      'id': '1',
      'name': 1,
      'year': '2026',
      'semester': '3',
      'timeTableOrder': '0',
    }.entries) {
      test('rejects ${entry.key} with the wrong type', () {
        final json = <String, dynamic>{
          'id': 1,
          'name': '시간표',
          'year': 2026,
          'semester': 3,
          'timeTableOrder': 0,
          entry.key: entry.value,
        };

        expect(
          () => TimetableListItem.fromV2Json(json),
          throwsA(isA<TypeError>()),
        );
      });
    }
  });

  group('Timetable.fromV2Detail', () {
    const summary = TimetableListItem(
      id: 1,
      name: '시간표',
      year: 2026,
      semester: 3,
      timeTableOrder: 0,
    );

    test('uses summary identity and semester to parse every lecture', () {
      final timetable = Timetable.fromV2Detail(detailFixture, summary: summary);

      expect(timetable.id, summary.id);
      expect(timetable.lectures, hasLength(1));
      expect(timetable.lectures.single.id, 1921750);
      expect(timetable.lectures.single.year, summary.year);
      expect(timetable.lectures.single.semester, summary.semester);
    });

    test('accepts an empty lectures list', () {
      final timetable = Timetable.fromV2Detail(<String, dynamic>{
        'lectures': <dynamic>[],
      }, summary: summary);

      expect(timetable.id, summary.id);
      expect(timetable.lectures, isEmpty);
    });

    test('rejects a missing lectures field', () {
      expect(
        () => Timetable.fromV2Detail(<String, dynamic>{}, summary: summary),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects a lecture missing required fields', () {
      expect(
        () => Timetable.fromV2Detail(<String, dynamic>{
          'lectures': <dynamic>[<String, dynamic>{}],
        }, summary: summary),
        throwsA(isA<TypeError>()),
      );
    });
  });

  test('keeps v1 Timetable.fromJson and toJson behavior', () {
    final timetable = Timetable.fromJson(<String, dynamic>{
      'id': 7,
      'lectures': <dynamic>[],
    });

    expect(timetable.id, 7);
    expect(timetable.lectures, isEmpty);
    expect(timetable.toJson(), <String, dynamic>{
      'id': 7,
      'lectures': <dynamic>[],
    });
  });
}
