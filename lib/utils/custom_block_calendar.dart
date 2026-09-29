import 'dart:convert';
import 'dart:typed_data';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/models/semester.dart';

Uint8List appendCustomBlocksToCalendar(
  Uint8List bytes,
  List<CustomBlock> blocks,
  Semester semester,
  int timetableId,
) {
  final calendar = utf8.decode(bytes);
  final end = calendar.lastIndexOf('END:VCALENDAR');
  if (end < 0) throw const FormatException('Invalid calendar response');
  String stamp(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}00';
  String escape(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', r'\n')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,');
  String fold(String line) {
    final output = StringBuffer();
    var length = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      final size = utf8.encode(char).length;
      if (length + size > 75) {
        output.write('\r\n ');
        length = 1;
      }
      output.write(char);
      length += size;
    }
    return output.toString();
  }

  final events = <String>[];
  final start = DateTime(
    semester.beginning.year,
    semester.beginning.month,
    semester.beginning.day,
  );
  final lastDay = DateTime(
    semester.end.year,
    semester.end.month,
    semester.end.day,
  );
  for (final block in blocks) {
    final day = start.add(
      Duration(days: (block.day + 1 - start.weekday + 7) % 7),
    );
    if (day.isAfter(lastDay)) continue;
    events.addAll([
      'BEGIN:VEVENT',
      'UID:custom-$timetableId-${block.id}@otl.kaist.ac.kr',
      'DTSTAMP:${stamp(DateTime.now().toUtc())}Z',
      'DTSTART;TZID=Asia/Seoul:${stamp(day.add(Duration(minutes: block.begin)))}',
      'DTEND;TZID=Asia/Seoul:${stamp(day.add(Duration(minutes: block.end)))}',
      'RRULE:FREQ=WEEKLY;UNTIL=${stamp(DateTime.utc(lastDay.year, lastDay.month, lastDay.day, 14, 59))}Z',
      fold('SUMMARY:${escape(block.name)}'),
      fold('LOCATION:${escape(block.place)}'),
      'END:VEVENT',
    ]);
  }
  return Uint8List.fromList(
    utf8.encode(
      '${calendar.substring(0, end).trimRight()}\r\n${events.join('\r\n')}\r\n${calendar.substring(end)}',
    ),
  );
}
