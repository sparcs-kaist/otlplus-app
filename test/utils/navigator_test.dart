import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/utils/navigator.dart';

void main() {
  testWidgets('pop is a no-op when tracked history is empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Builder(builder: _buildTestPage)),
    );

    final context = tester.element(find.byKey(const ValueKey('test-page')));

    expect(() => OTLNavigator.pop(context), returnsNormally);
    expect(OTLNavigator.canPop, isFalse);
  });
}

Widget _buildTestPage(BuildContext context) =>
    const SizedBox(key: ValueKey('test-page'));
