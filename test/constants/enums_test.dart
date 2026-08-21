import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/enums.dart';

void main() {
  group('Season', () {
    test('maps each API code to its typed season and translation key', () {
      expect(Season.fromCode(1), Season.spring);
      expect(Season.spring.code, 1);
      expect(Season.spring.labelKey, 'semester.spring');

      expect(Season.fromCode(2), Season.summer);
      expect(Season.summer.code, 2);
      expect(Season.summer.labelKey, 'semester.summer');

      expect(Season.fromCode(3), Season.fall);
      expect(Season.fall.code, 3);
      expect(Season.fall.labelKey, 'semester.fall');

      expect(Season.fromCode(4), Season.winter);
      expect(Season.winter.code, 4);
      expect(Season.winter.labelKey, 'semester.winter');
    });

    test('returns null for an unknown API code', () {
      expect(Season.fromCode(0), isNull);
      expect(Season.fromCode(5), isNull);
    });
  });

  test('declares review tabs, timetable modes, and tab actions', () {
    expect(
      ReviewTab.values,
      containsAll(<ReviewTab>[ReviewTab.hallOfFame, ReviewTab.latest]),
    );
    expect(
      TimetableViewMode.values,
      containsAll(<TimetableViewMode>[
        TimetableViewMode.classes,
        TimetableViewMode.exams,
        TimetableViewMode.map,
      ]),
    );
    expect(
      TimetableTabAction.values,
      containsAll(<TimetableTabAction>[
        TimetableTabAction.copy,
        TimetableTabAction.exportImage,
        TimetableTabAction.exportIcal,
        TimetableTabAction.delete,
      ]),
    );
  });
}
