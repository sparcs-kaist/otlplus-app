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
