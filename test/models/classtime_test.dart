import 'dart:convert';
import 'package:otlplus/models/classtime.dart';
import 'package:test/test.dart';
import '../utils/samples.dart';

void main() {
  group('Classtime', () {
    test('constructor', () {
      expect(SampleClasstime.shared.runtimeType, Classtime);
    });

    test('fromJson', () {
      final classtimeFromJson = Classtime.fromJson(
        jsonDecode(SampleClasstime.json),
      );
      expect(classtimeFromJson == SampleClasstime.shared, true);
    });

    test('toJson', () {
      expect(SampleClasstime.shared.toJson(), jsonDecode(SampleClasstime.json));
    });
  });
}
