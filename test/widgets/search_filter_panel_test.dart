import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/filter.dart';
import 'package:otlplus/widgets/search_filter_panel.dart';

void main() {
  testWidgets('renders filter groups and scrolls through a tall filter list', (
    tester,
  ) async {
    final filter = {
      'department': FilterGroupInfo(
        label: 'Department',
        options: [
          [
            CodeLabelPair(code: 'cs', label: 'CS'),
            CodeLabelPair(code: 'ee', label: 'EE'),
          ],
        ],
      ),
      'level': FilterGroupInfo(
        label: 'Level',
        options: [
          [
            CodeLabelPair(code: '100', label: '100'),
            CodeLabelPair(code: '200', label: '200'),
          ],
        ],
      ),
      'semester': FilterGroupInfo(
        label: 'Semester',
        options: [
          [
            CodeLabelPair(code: 'spring', label: 'SP'),
            CodeLabelPair(code: 'fall', label: 'FA'),
          ],
        ],
      ),
      'format': FilterGroupInfo(
        label: 'Format',
        options: [
          [
            CodeLabelPair(code: 'in-person', label: 'IP'),
            CodeLabelPair(code: 'online', label: 'ON'),
          ],
        ],
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: SearchFilterPanel(
              filter: filter,
              setFilter: (_, __, ___) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Department'), findsOneWidget);
    expect(find.text('CS'), findsOneWidget);
    expect(find.text('Format'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('ON'), findsOneWidget);
  });
}
