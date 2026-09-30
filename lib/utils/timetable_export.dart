import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/models/semester.dart';

/// Exports saved lectures and custom blocks; preview lectures are excluded.
class TimetableExport {
  static String _title(Lecture lecture, String language) =>
      language == 'ko' || lecture.titleEn.isEmpty
      ? lecture.title
      : lecture.titleEn;

  static List<_ExportEntry> _entries(
    List<Lecture> lectures,
    List<CustomBlock> blocks,
    String language,
  ) => [
    for (final lecture in lectures)
      for (var index = 0; index < lecture.classtimes.length; index++)
        _ExportEntry(
          uid: '${lecture.id}-$index',
          day: lecture.classtimes[index].day.code,
          begin: lecture.classtimes[index].begin,
          end: lecture.classtimes[index].end,
          title: _title(lecture, language),
          location:
              '${lecture.classtimes[index].buildingCode} ${lecture.classtimes[index].roomName}'
                  .trim(),
          description:
              '${'${lecture.classtimes[index].buildingCode} ${lecture.classtimes[index].roomName}'.trim()}\n${lecture.professors.map((professor) => language == 'ko' || professor.nameEn.isEmpty ? professor.name : professor.nameEn).join(', ')}',
          color: OTLColor.blockColors[lecture.course % 16],
        ),
    for (final block in blocks)
      for (var index = 0; index < block.occurrences.length; index++)
        _ExportEntry(
          uid: 'custom-${block.id}-$index',
          day: block.occurrences[index].day,
          begin: block.occurrences[index].begin,
          end: block.occurrences[index].end,
          title: block.name,
          location: block.place,
          description: block.place,
          color: OTLColor
              .blockColors[(block.id * 3 + 7) % OTLColor.blockColors.length],
        ),
  ];

  static String _semesterTitle(Semester semester, String language) {
    final seasons = language == 'ko'
        ? ['봄', '여름', '가을', '겨울']
        : ['Spring', 'Summer', 'Fall', 'Winter'];
    final index = semester.semester - 1;
    return '${semester.year} ${index >= 0 && index < 4 ? seasons[index] : ''}'
        .trim();
  }

  static Future<Uint8List> image({
    required List<Lecture> lectures,
    List<CustomBlock> customBlocks = const [],
    required Semester semester,
    required String name,
    required String language,
  }) async {
    final lang = language == 'ko' ? 'ko' : 'en';
    final entries = _entries(lectures, customBlocks, lang);
    final startMinute = entries.fold(
      480,
      (start, entry) => math.min(start, entry.begin ~/ 60 * 60),
    );
    final extraHeight = (480 - startMinute) * 4 / 3;
    final weekend = entries.any((entry) => entry.day >= 5);
    final data = await rootBundle.load(
      'assets/images/timetable/Image_template_${weekend ? 7 : 5}days_light_$lang.png',
    );
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final template = (await codec.getNextFrame()).image;
    codec.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.white, BlendMode.src);
    // Keep the existing template and extend its grid above 08:00 when needed.
    canvas.drawImageRect(
      template,
      Rect.fromLTWH(0, 0, template.width.toDouble(), 154),
      Rect.fromLTWH(0, 0, template.width.toDouble(), 154),
      Paint(),
    );
    canvas.drawImageRect(
      template,
      Rect.fromLTWH(0, 154, template.width.toDouble(), template.height - 154.0),
      Rect.fromLTWH(
        0,
        154 + extraHeight,
        template.width.toDouble(),
        template.height - 154.0,
      ),
      Paint(),
    );
    if (extraHeight > 0) {
      final gridPaint = Paint()..color = const Color(0xffdddddd);
      final dayCount = weekend ? 7 : 5;
      for (var minute = startMinute; minute <= 480; minute += 60) {
        final y = 154 + (minute - startMinute) * 4 / 3;
        for (var day = 0; day < dayCount; day++) {
          final x = 76 + 178.0 * day;
          canvas.drawLine(Offset(x, y), Offset(x + 171, y), gridPaint);
        }
        for (var x = 76.0; x < template.width - 36; x += 6) {
          canvas.drawLine(Offset(x, y + 40), Offset(x + 2, y + 40), gridPaint);
        }
      }
      // Redraw the hour gutter so the original 08:00 label is not split at
      // the template seam. Use the same twelve-hour labels throughout.
      canvas.drawRect(
        Rect.fromLTWH(0, 130, 70, template.height + extraHeight - 130),
        Paint()..color = Colors.white,
      );
      for (var minute = startMinute; minute <= 1440; minute += 60) {
        final hour = minute ~/ 60;
        final label = TextPainter(
          text: TextSpan(
            text: '${(hour + 11) % 12 + 1}',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 18,
              color: const Color(0xff888888),
              fontWeight: hour % 6 == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          Offset(
            60 - label.width,
            154 + (minute - startMinute) * 4 / 3 - label.height / 2,
          ),
        );
        label.dispose();
      }
    }
    final header = TextPainter(
      text: TextSpan(
        text: '${_semesterTitle(semester, lang)} $name',
        style: const TextStyle(
          fontFamily: 'NotoSansKR',
          fontSize: 30,
          color: Color(0xffcccccc),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: template.width - 360);
    header.paint(canvas, Offset((weekend ? 1302 : 952) - header.width, 43));
    header.dispose();
    for (final entry in entries) {
      if (entry.end <= entry.begin) continue;
      final rect = Rect.fromLTWH(
        178.0 * entry.day + 76,
        (entry.begin - startMinute) * 4 / 3 + 154,
        171,
        math.max(1, (entry.end - entry.begin) * 4 / 3 - 7),
      );
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(
          76,
          154,
          template.width - 36,
          template.height + extraHeight - 49,
        ),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = entry.color,
      );
      if (rect.height > 16) {
        canvas.clipRect(rect.deflate(8));
        final painter = TextPainter(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 18,
              height: 1.25,
              color: Colors.black,
            ),
            children: [
              TextSpan(text: '${entry.title}\n'),
              TextSpan(
                text: entry.description,
                style: const TextStyle(color: Color(0xff888888)),
              ),
            ],
          ),
          textDirection: TextDirection.ltr,
          maxLines: 3,
          ellipsis: '…',
        )..layout(maxWidth: rect.width - 24);
        painter.paint(canvas, rect.topLeft + const Offset(12, 8));
        painter.dispose();
      }
      canvas.restore();
    }
    final picture = recorder.endRecording();
    try {
      final result = await picture.toImage(
        template.width,
        template.height + extraHeight.ceil(),
      );
      try {
        final bytes = await result.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError('PNG encoding failed');
        return bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
      } finally {
        result.dispose();
      }
    } finally {
      picture.dispose();
      template.dispose();
    }
  }

  /// Korean class times are encoded as UTC, independent of the device timezone.
  static Uint8List calendar({
    required List<Lecture> lectures,
    List<CustomBlock> customBlocks = const [],
    required Semester semester,
    required String name,
    required String language,
    DateTime? now,
  }) {
    DateTime koreanDate(DateTime value) {
      final date = value.isUtc ? value.add(const Duration(hours: 9)) : value;
      return DateTime.utc(date.year, date.month, date.day);
    }

    String stamp(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}Z';
    String escape(String value) => value
        .replaceAll('\\', '\\\\')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\n', r'\n')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,');
    final beginning = koreanDate(semester.beginning);
    final end = koreanDate(semester.end);
    final until = end.add(const Duration(hours: 14, minutes: 59, seconds: 59));
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//SPARCS//OTL Plus//EN',
      'CALSCALE:GREGORIAN',
      'X-WR-CALNAME:${escape(name)}',
      'X-WR-TIMEZONE:Asia/Seoul',
    ];
    for (final entry in _entries(lectures, customBlocks, language)) {
      if (entry.end <= entry.begin) continue;
      final first = beginning.add(
        Duration(days: (entry.day + 1 - beginning.weekday + 7) % 7),
      );
      if (first.isAfter(end)) continue;
      final start = first.add(Duration(minutes: entry.begin - 540));
      final finish = first.add(Duration(minutes: entry.end - 540));
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:${semester.year}-${semester.semester}-${entry.uid}@otl.sparcs.org',
        'DTSTAMP:${stamp((now ?? DateTime.now()).toUtc())}',
        'DTSTART:${stamp(start)}',
        'DTEND:${stamp(finish)}',
        'RRULE:FREQ=WEEKLY;UNTIL=${stamp(until)}',
        'SUMMARY:${escape(entry.title)}',
        'LOCATION:${escape(entry.location)}',
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'TRIGGER:-PT15M',
        'DESCRIPTION:${escape(entry.title)}',
        'END:VALARM',
        'END:VEVENT',
      ]);
    }
    lines.add('END:VCALENDAR');
    // RFC 5545 folds at 75 octets without splitting a UTF-8 code point.
    final folded = <String>[];
    for (final line in lines) {
      var chunk = '';
      var length = 0;
      for (final rune in line.runes) {
        final char = String.fromCharCode(rune);
        final size = utf8.encode(char).length;
        if (length + size > 75) {
          folded.add(chunk);
          chunk = ' ';
          length = 1;
        }
        chunk += char;
        length += size;
      }
      folded.add(chunk);
    }
    return Uint8List.fromList(utf8.encode('${folded.join('\r\n')}\r\n'));
  }
}

class _ExportEntry {
  const _ExportEntry({
    required this.uid,
    required this.day,
    required this.begin,
    required this.end,
    required this.title,
    required this.location,
    required this.description,
    required this.color,
  });
  final String uid;
  final int day;
  final int begin;
  final int end;
  final String title;
  final String location;
  final String description;
  final Color color;
}
