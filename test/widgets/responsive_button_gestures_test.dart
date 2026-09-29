import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/widgets/responsive_button.dart';

void main() {
  testWidgets('long press does not also dispatch a tap on release', (
    tester,
  ) async {
    var taps = 0;
    var holds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackgroundButton(
            onTap: () => taps++,
            onLongPress: () => holds++,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Text('Lecture'),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Lecture')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(holds, 1);
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(taps, 0);
  });

  testWidgets('removing a pressed button cancels its delayed action', (
    tester,
  ) async {
    var holds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackgroundButton(
            onLongPress: () => holds++,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Text('Remove'),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Remove')),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    expect(holds, 0);
    expect(tester.takeException(), isNull);
  });
}
