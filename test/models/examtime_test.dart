import 'dart:convert';
import 'package:test/test.dart';
import 'package:otlplus/models/examtime.dart';

void main() {
  group('Examtime', () {
    String str = 'str';
    String strEn = 'str_en';
    int day = 1;
    int begin = 2;
    int end = 3;
    String json =
        """
      {
        "str": "$str",
        "str_en": "$strEn",
        "day": $day,
        "begin": $begin,
        "end": $end
      }
      """;
    Examtime examtime = Examtime(
      str: str,
      strEn: strEn,
      day: day,
      begin: begin,
      end: end,
    );

    test('constructor', () {
      expect(examtime.str, str);
      expect(examtime.strEn, strEn);
      expect(examtime.day, day);
      expect(examtime.begin, begin);
      expect(examtime.end, end);
    });

    test('fromJson', () {
      var examtimeFromJson = Examtime.fromJson(jsonDecode(json));
      expect(examtimeFromJson == examtime, true);
    });

    test('toJson', () {
      expect(examtime.toJson(), jsonDecode(json));
    });
  });
}
