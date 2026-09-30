import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/repositories/timetable_repository.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/models/classtime.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/utils/timetable_export.dart';
import '../utils/samples.dart';

void main() {
  final semester = Semester(
    year: 2026,
    semester: 1,
    beginning: DateTime.parse('2026-03-02T00:00:00+09:00'),
    end: DateTime.parse('2026-06-19T00:00:00+09:00'),
  );
  Lecture lecture(int day) {
    final lecture = Lecture.fromJson({
      ...SampleLecture.shared.toJson(),
      'title': '컴퓨터, 프로그래밍; 기초\\실습\n한글' * 4,
    });
    lecture.classtimes = [
      Classtime(
        buildingCode: 'E3',
        classroom: '',
        classroomEn: '',
        classroomShort: '',
        classroomShortEn: '',
        roomName: '101',
        day: day,
        begin: 540,
        end: 630,
      ),
    ];
    return lecture;
  }

  test(
    'calendar uses Korean time, weekly recurrence, alarms and UTF8 folding',
    () {
      final bytes = TimetableExport.calendar(
        lectures: [lecture(1)],
        semester: semester,
        name: '내 시간표',
        language: 'ko',
        now: DateTime.utc(2026),
      );
      final raw = utf8.decode(bytes);
      final text = raw.replaceAll('\r\n ', '');
      expect(text, contains('DTSTART:20260303T000000Z'));
      expect(text, contains('DTEND:20260303T013000Z'));
      expect(text, contains('RRULE:FREQ=WEEKLY;UNTIL=20260619T145959Z'));
      expect(text, contains('TRIGGER:-PT15M'));
      expect(text, contains(r'컴퓨터\, 프로그래밍\; 기초\\실습\n한글'));
      expect(raw.endsWith('END:VCALENDAR\r\n'), isTrue);
      for (final line in raw.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
    },
  );

  test(
    'custom calendar includes every time, midnight and escaped location',
    () {
      final text = utf8
          .decode(
            TimetableExport.calendar(
              lectures: [lecture(0)],
              customBlocks: [
                const CustomBlock(
                  id: 7,
                  name: 'Study, session',
                  place: 'Room; A',
                  day: 0,
                  begin: 0,
                  end: 60,
                  times: [
                    CustomBlockTime(day: 0, begin: 0, end: 60),
                    CustomBlockTime(day: 6, begin: 1380, end: 1440),
                  ],
                ),
              ],
              semester: semester,
              name: 'Mixed',
              language: 'en',
              now: DateTime.utc(2026),
            ),
          )
          .replaceAll('\r\n ', '');
      expect('BEGIN:VEVENT'.allMatches(text), hasLength(3));
      expect(text, contains('DTSTART:20260301T150000Z'));
      expect(text, contains('DTEND:20260308T150000Z'));
      expect(text, contains(r'SUMMARY:Study\, session'));
      expect(text, contains(r'LOCATION:Room\; A'));
      expect(text, contains('UID:2026-1-custom-7-1@otl.sparcs.org'));
    },
  );

  testWidgets('custom-only weekend image extends grid for midnight', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await (FontLoader('NotoSansKR')
            ..addFont(rootBundle.load('assets/fonts/NotoSansKR-Regular.otf')))
          .load();
      final bytes = await TimetableExport.image(
        lectures: [],
        customBlocks: [
          const CustomBlock(
            id: 7,
            name: 'Midnight study',
            place: 'Library',
            day: 6,
            begin: 0,
            end: 60,
          ),
        ],
        semester: semester,
        name: 'Custom blocks',
        language: 'en',
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1350);
      expect(frame.image.height, 2120);
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      // Inside the Sunday custom block, away from its text and rounded edge.
      final offset = (200 * frame.image.width + 1290) * 4;
      expect(pixels!.getUint8(offset), lessThan(255));
      await File('/tmp/otl-custom-export-preview.png').writeAsBytes(bytes);
      frame.image.dispose();
      codec.dispose();
    });
  });

  test('model exports locally through writer without HTTP', () async {
    final dio = Dio();
    var requests = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests++;
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );
    String? calendar;
    final model = TimetableModel(
      repository: TimetableRepository(dio),
      forTest: true,
      fileWriter: (type, bytes) async {
        expect(type, ShareType.ical);
        calendar = utf8.decode(bytes!);
      },
    );
    expect(await model.shareTimetable(ShareType.ical, 'ko'), isTrue);
    expect(calendar, contains('BEGIN:VCALENDAR'));
    expect(requests, 0);
    model.dispose();
  });

  testWidgets('renders both templates and language variants as PNG', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await (FontLoader('NotoSansKR')
            ..addFont(rootBundle.load('assets/fonts/NotoSansKR-Regular.otf')))
          .load();
      for (final lang in ['ko', 'en']) {
        for (final day in [0, 6]) {
          final bytes = await TimetableExport.image(
            lectures: [lecture(day)],
            semester: semester,
            name: '이름 없음',
            language: lang,
          );
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, day == 0 ? 994 : 1350);
          expect(frame.image.height, 1480);
          if (lang == 'ko' && day == 0) {
            await File('/tmp/otl-export-preview.png').writeAsBytes(bytes);
          }
          frame.image.dispose();
          codec.dispose();
        }
      }
    });
  });
}
