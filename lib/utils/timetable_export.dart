import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/semester.dart';

/// Local exports use saved lectures only; preview and custom blocks are excluded.
class TimetableExport {
  static String _title(Lecture lecture, String language) =>
      language == 'ko' || lecture.titleEn.isEmpty
      ? lecture.title
      : lecture.titleEn;

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
    required Semester semester,
    required String name,
    required String language,
  }) async {
    final lang = language == 'ko' ? 'ko' : 'en';
    final weekend = lectures.any(
      (lecture) => lecture.classtimes.any((time) => time.day.code >= 5),
    );
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
    canvas.drawImage(template, Offset.zero, Paint());
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
    for (final lecture in lectures) {
      for (final time in lecture.classtimes) {
        if (time.end <= time.begin) continue;
        final rect = Rect.fromLTWH(
          178.0 * time.day.code + 76,
          time.begin * 4 / 3 - 486,
          171,
          (time.end - time.begin) * 4 / 3 - 7,
        );
        canvas.save();
        canvas.clipRect(
          Rect.fromLTRB(76, 154, template.width - 36, template.height - 49),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = OTLColor.blockColors[lecture.course % 16],
        );
        if (rect.height > 16) {
          canvas.clipRect(rect.deflate(8));
          final professors = lecture.professors
              .map(
                (professor) => lang == 'ko' || professor.nameEn.isEmpty
                    ? professor.name
                    : professor.nameEn,
              )
              .join(', ');
          final painter = TextPainter(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 18,
                height: 1.25,
                color: Colors.black,
              ),
              children: [
                TextSpan(text: '${_title(lecture, lang)}\n'),
                TextSpan(
                  text:
                      '${'${time.buildingCode} ${time.roomName}'.trim()}\n$professors',
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
    }
    final picture = recorder.endRecording();
    try {
      final result = await picture.toImage(template.width, template.height);
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
    for (final lecture in lectures) {
      for (var index = 0; index < lecture.classtimes.length; index++) {
        final time = lecture.classtimes[index];
        if (time.end <= time.begin) continue;
        final first = beginning.add(
          Duration(days: (time.day.code + 1 - beginning.weekday + 7) % 7),
        );
        if (first.isAfter(end)) continue;
        final start = first.add(Duration(minutes: time.begin - 540));
        final finish = first.add(Duration(minutes: time.end - 540));
        lines.addAll([
          'BEGIN:VEVENT',
          'UID:${semester.year}-${semester.semester}-${lecture.id}-$index@otl.sparcs.org',
          'DTSTAMP:${stamp((now ?? DateTime.now()).toUtc())}',
          'DTSTART:${stamp(start)}',
          'DTEND:${stamp(finish)}',
          'RRULE:FREQ=WEEKLY;UNTIL=${stamp(until)}',
          'SUMMARY:${escape(_title(lecture, language))}',
          'LOCATION:${escape('${time.buildingCode} ${time.roomName}'.trim())}',
          'BEGIN:VALARM',
          'ACTION:DISPLAY',
          'TRIGGER:-PT15M',
          'DESCRIPTION:${escape(_title(lecture, language))}',
          'END:VALARM',
          'END:VEVENT',
        ]);
      }
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
