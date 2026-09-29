import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/utils/custom_block_calendar.dart';

void main() {
  test(
    'calendar preserves lecture events and adds weekly blocks including midnight',
    () {
      final result = utf8.decode(
        appendCustomBlocksToCalendar(
          Uint8List.fromList(
            utf8.encode(
              'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nSUMMARY:Lecture\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n',
            ),
          ),
          [
            const CustomBlock(
              id: 1,
              name: 'Study, plan;\nNext',
              place: 'Library',
              day: 0,
              begin: 1380,
              end: 1440,
            ),
          ],
          Semester(
            year: 2026,
            semester: 3,
            beginning: DateTime(2026, 8, 31),
            end: DateTime(2026, 12, 18),
          ),
          7,
        ),
      );
      expect(result, contains('SUMMARY:Lecture'));
      expect(result, contains(r'SUMMARY:Study\, plan\;\nNext'));
      expect(result, contains('DTSTART;TZID=Asia/Seoul:20260831T230000'));
      expect(result, contains('DTEND;TZID=Asia/Seoul:20260901T000000'));
      expect(result, contains('RRULE:FREQ=WEEKLY;UNTIL=20261218T145900Z'));
      expect(result.endsWith('END:VCALENDAR\r\n'), isTrue);
    },
  );
}
