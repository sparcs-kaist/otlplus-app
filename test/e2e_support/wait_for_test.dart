import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/wait_for.dart';

void main() {
  testWidgets('waitForAny returns the key of the first matching outcome', (
    tester,
  ) async {
    await tester.pumpWidget(const _FramesLaterWidget(frames: 3));

    final key = await waitForAny(
      tester,
      <String, Finder>{
        'ready': find.text('ready'),
        'error': find.text('error'),
      },
      stage: 'appearing-outcome',
      timeout: const Duration(seconds: 5),
    );

    expect(key, 'ready');
  });

  testWidgets('waitForAny rethrows widget exceptions with the stage prefix', (
    tester,
  ) async {
    await tester.pumpWidget(const _ThrowingWidget());

    var returned = false;
    try {
      await waitForAny(
        tester,
        <String, Finder>{'never': find.text('never')},
        stage: 'boom-stage',
        timeout: const Duration(seconds: 5),
      );
      returned = true;
    } on TestFailure catch (failure) {
      expect(failure.message, contains('[boom-stage]'));
    }
    expect(returned, isFalse);
  });

  testWidgets('waitForAny times out with stage and expected outcome keys', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());

    var returned = false;
    try {
      await waitForAny(
        tester,
        <String, Finder>{
          'alpha': find.text('alpha'),
          'beta': find.text('beta'),
        },
        stage: 'slow-stage',
        timeout: const Duration(milliseconds: 200),
      );
      returned = true;
    } on TestFailure catch (failure) {
      expect(failure.message, contains('slow-stage'));
      expect(failure.message, contains('alpha'));
      expect(failure.message, contains('beta'));
    }
    expect(returned, isFalse);
  });

  testWidgets('step passes values through and prefixes failures', (
    tester,
  ) async {
    final value = await step<int>('ok-step', () async => 7);
    expect(value, 7);

    var caught = false;
    try {
      await step<void>('bad-step', () async {
        fail('inner boom');
      });
    } on TestFailure catch (failure) {
      caught = true;
      expect(failure.message, contains('[step:bad-step]'));
      expect(failure.message, contains('inner boom'));
    }
    expect(caught, isTrue);
  });

  testWidgets('waitUntilGone resolves once the finder stops matching', (
    tester,
  ) async {
    await tester.pumpWidget(const _FramesLaterWidget(frames: 2));

    await waitUntilGone(
      tester,
      find.text('waiting'),
      stage: 'gone-stage',
      timeout: const Duration(seconds: 5),
    );

    expect(find.text('waiting'), findsNothing);
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('waitUntilGone times out with the stage name', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    var returned = false;
    try {
      await waitUntilGone(
        tester,
        find.byType(SizedBox),
        stage: 'stuck-stage',
        timeout: const Duration(milliseconds: 200),
      );
      returned = true;
    } on TestFailure catch (failure) {
      expect(failure.message, contains('stuck-stage'));
    }
    expect(returned, isFalse);
  });

  testWidgets(
    'waitUntilGone rethrows widget exceptions with the stage prefix',
    (tester) async {
      await tester.pumpWidget(const _ThrowingWidget());

      var returned = false;
      try {
        await waitUntilGone(
          tester,
          find.byType(SizedBox),
          stage: 'gone-boom-stage',
          timeout: const Duration(seconds: 5),
        );
        returned = true;
      } on TestFailure catch (failure) {
        expect(failure.message, contains('[gone-boom-stage]'));
        expect(failure.message, contains('deliberate build failure'));
      }
      expect(returned, isFalse);
    },
  );

  testWidgets('waitForAny rejects empty outcome maps immediately', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());

    expect(
      () => waitForAny(tester, const <String, Finder>{}, stage: 'empty'),
      throwsArgumentError,
    );
  });
}

class _FramesLaterWidget extends StatefulWidget {
  const _FramesLaterWidget({required this.frames});

  final int frames;

  @override
  State<_FramesLaterWidget> createState() => _FramesLaterWidgetState();
}

class _FramesLaterWidgetState extends State<_FramesLaterWidget> {
  int _ticks = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        setState(() {
          _ticks++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Text(_ticks >= widget.frames ? 'ready' : 'waiting')),
    );
  }
}

class _ThrowingWidget extends StatelessWidget {
  const _ThrowingWidget();

  @override
  Widget build(BuildContext context) {
    throw StateError('deliberate build failure');
  }
}
