import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/repositories/timetable_repository.dart';
import 'package:otlplus/widgets/timetable_summary.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/extensions.dart';
import '../utils/samples.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pump(
    WidgetTester tester,
    List<Lecture> lectures, {
    Lecture? preview,
  }) async {
    final model = TimetableModel(
      repository: TimetableRepository(Dio()),
      forTest: true,
    );
    model.currentTimetable.lectures = lectures;
    model.setTempLecture(preview);
    await tester.pumpWidget(
      ChangeNotifierProvider<TimetableModel>.value(
        value: model,
        child: const TimetableSummary().scaffold,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses unweighted averages and floors the web score scale', (
    tester,
  ) async {
    await pump(tester, [
      _lecture(1, grade: 3, load: 6, speech: 12, credit: 1),
      _lecture(2, grade: 6, load: 9, speech: 15, credit: 5),
      _lecture(3, grade: 0, load: 0, speech: 0, credit: 9),
    ]);
    expect(find.text('D'), findsOneWidget); // 4.5
    expect(find.text('C'), findsOneWidget); // 7.5
    expect(find.text('A'), findsOneWidget); // 13.5
  });

  testWidgets(
    'includes zero metrics when another metric is nonzero, including preview',
    (tester) async {
      await pump(tester, [
        _lecture(1, grade: 3, load: 6, speech: 12),
        _lecture(2, grade: 6, load: 9, speech: 15),
      ], preview: _lecture(3, grade: 0, load: 3, speech: 0));
      expect(find.text('D-'), findsOneWidget); // 3
      expect(find.text('C-'), findsOneWidget); // 6
      expect(find.text('B-'), findsOneWidget); // 9
    },
  );

  testWidgets('empty or wholly unrated timetables show unknown scores', (
    tester,
  ) async {
    for (final lectures in <List<Lecture>>[
      [],
      [_lecture(1, grade: 0, load: 0, speech: 0)],
    ]) {
      await pump(tester, lectures);
      expect(find.text('?'), findsNWidgets(3));
    }
  });

  testWidgets('uses F for a zero metric and caps high scores at A+', (
    tester,
  ) async {
    await pump(tester, [_lecture(1, grade: 0, load: 15, speech: 18)]);
    expect(find.text('F'), findsOneWidget);
    expect(find.text('A+'), findsNWidgets(2));
  });
}

Lecture _lecture(
  int id, {
  required double grade,
  required double load,
  required double speech,
  int credit = 3,
}) => Lecture.fromJson({
  ...SampleLecture.shared.toJson(),
  'id': id,
  'grade': grade,
  'load': load,
  'speech': speech,
  'credit': credit,
  'credit_au': 0,
  'review_total_weight': 0.0,
});
