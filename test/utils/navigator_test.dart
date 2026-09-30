import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';

void main() {
  testWidgets('pop is a no-op on the root route', (tester) async {
    await tester.pumpWidget(MaterialApp(home: _page('root')));
    final context = tester.element(find.byKey(const ValueKey('root')));
    OTLNavigator.pop(context);
    expect(OTLNavigator.canPop, isFalse);
    expect(find.byKey(const ValueKey('root')), findsOneWidget);
  });

  for (final transition in OTLNavigatorTransition.values) {
    testWidgets(
      'rebuilding a covered root does not inherit $transition buttons',
      (tester) async {
        final revision = ValueNotifier(0);
        addTearDown(revision.dispose);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: ValueListenableBuilder<int>(
              valueListenable: revision,
              builder: (_, value, __) => _page('root-$value'),
            ),
          ),
        );
        final root = tester.element(find.byKey(const ValueKey('root-0')));
        OTLNavigator.push(root, _page('settings'), transition: transition);
        await tester.pumpAndSettle();
        final settings = tester.element(find.byKey(const ValueKey('settings')));
        expect(
          OTLNavigator.canPopRightLeftOf(settings),
          transition == OTLNavigatorTransition.rightLeft,
        );
        expect(
          OTLNavigator.canPopDownUpOf(settings),
          transition != OTLNavigatorTransition.rightLeft,
        );

        // Locale changes can recreate layouts under the settings route.
        revision.value++;
        await tester.pumpAndSettle();
        final rebuiltRoot = tester.element(
          find.byKey(const ValueKey('root-1'), skipOffstage: false),
        );
        expect(OTLNavigator.canPopRightLeftOf(rebuiltRoot), isFalse);
        expect(OTLNavigator.canPopDownUpOf(rebuiltRoot), isFalse);
        OTLNavigator.pop(rebuiltRoot, until: transition);
        expect(navigator.currentState!.canPop(), isTrue);

        // Android system back bypasses OTLNavigator.pop.
        await navigator.currentState!.maybePop();
        await tester.pumpAndSettle();
        expect(OTLNavigator.canPop, isFalse);
        expect(find.byIcon(Icons.navigate_before), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
        expect(find.byKey(const ValueKey('root-1')), findsOneWidget);
      },
    );
  }

  testWidgets('close button unwinds mixed transitions after system back', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: _page('root')),
    );
    OTLNavigator.push(
      tester.element(find.byKey(const ValueKey('root'))),
      _page('settings'),
      transition: OTLNavigatorTransition.downUp,
    );
    await tester.pumpAndSettle();
    OTLNavigator.push(
      tester.element(find.byKey(const ValueKey('settings'))),
      _page('detail'),
    );
    await tester.pumpAndSettle();
    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(OTLNavigator.canPopRightLeft, isFalse);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(OTLNavigator.canPop, isFalse);
    expect(find.byKey(const ValueKey('root')), findsOneWidget);

    OTLNavigator.push(
      tester.element(find.byKey(const ValueKey('root'))),
      _page('settings'),
      transition: OTLNavigatorTransition.downUp,
    );
    await tester.pumpAndSettle();
    OTLNavigator.push(
      tester.element(find.byKey(const ValueKey('settings'))),
      _page('detail'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(OTLNavigator.canPop, isFalse);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(find.byKey(const ValueKey('root')), findsOneWidget);
  });

  for (final transition in [
    OTLNavigatorTransition.rightLeft,
    OTLNavigatorTransition.downUp,
  ]) {
    testWidgets('iOS edge swipe pops $transition and clears history', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: _page('root'),
        ),
      );
      OTLNavigator.push(
        tester.element(find.byKey(const ValueKey('root'))),
        _page('detail'),
        transition: transition,
      );
      await tester.pumpAndSettle();
      final detail = tester.element(find.byKey(const ValueKey('detail')));
      expect(ModalRoute.of(detail), isA<CupertinoPageRoute<dynamic>>());
      expect(ModalRoute.of(detail)!.popGestureEnabled, isTrue);

      // A short, slow swipe cancels, preserving both route and history.
      await tester.timedDragFrom(
        const Offset(1, 300),
        const Offset(40, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detail')), findsOneWidget);
      expect(OTLNavigator.canPop, isTrue);

      await tester.timedDragFrom(
        const Offset(1, 300),
        const Offset(600, 0),
        const Duration(milliseconds: 500),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('root')), findsOneWidget);
      expect(OTLNavigator.canPop, isFalse);
      expect(find.byIcon(Icons.navigate_before), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  }

  testWidgets('barrier dismissal removes only the dialog history', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: _page('root')),
    );
    OTLNavigator.push(
      tester.element(find.byKey(const ValueKey('root'))),
      _page('detail'),
    );
    await tester.pumpAndSettle();
    OTLNavigator.pushDialog<void>(
      context: tester.element(find.byKey(const ValueKey('detail'))),
      builder: (_) => const Center(child: SizedBox(width: 100, height: 100)),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(OTLNavigator.canPopRightLeft, isTrue);
    OTLNavigator.pop(tester.element(find.byKey(const ValueKey('detail'))));
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isFalse);
    expect(OTLNavigator.canPop, isFalse);
    expect(find.byKey(const ValueKey('root')), findsOneWidget);
  });
}

Widget _page(String name) => OTLScaffold(
  child: OTLLayout(
    key: ValueKey(name),
    middle: Text(name),
    body: const SizedBox.expand(),
  ),
);
