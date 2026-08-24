import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Waits until one of [outcomes] becomes findable in the widget tree.
///
/// Pumps the tree in short intervals until the first matching outcome (in
/// [Map] insertion order) appears, a widget exception surfaces, or [timeout]
/// elapses. Unlike [WidgetTester.pumpAndSettle] this can never hang forever,
/// and failures carry the [stage] name so flaky CI logs stay diagnosable.
///
/// Returns the key of the outcome that matched.
Future<String> waitForAny(
  WidgetTester tester,
  Map<String, Finder> outcomes, {
  required String stage,
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (outcomes.isEmpty) {
    throw ArgumentError.value(outcomes, 'outcomes', 'must not be empty');
  }

  final interval = const Duration(milliseconds: 100);
  final elapsed = Stopwatch()..start();

  while (elapsed.elapsed < timeout) {
    await tester.pump(interval);

    final exception = tester.takeException();
    if (exception != null) {
      fail('[$stage] Flutter exception: $exception');
    }

    for (final outcome in outcomes.entries) {
      if (tester.any(outcome.value)) {
        debugPrint('✔ $stage -> ${outcome.key}');
        return outcome.key;
      }
    }
  }

  fail(
    '[$stage] Timed out after ${timeout.inSeconds}s. '
    'Expected one of: ${outcomes.keys.join(', ')}',
  );
}

/// Waits until [finder] no longer matches anything in the widget tree.
///
/// Bounded counterpart to `pumpAndSettle` for dismissible/transient UI
/// (snackbars, dialogs, spinners) where the wanted state is an absence.
Future<void> waitUntilGone(
  WidgetTester tester,
  Finder finder, {
  required String stage,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final elapsed = Stopwatch()..start();

  while (elapsed.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));

    final exception = tester.takeException();
    if (exception != null) {
      fail('[$stage] Flutter exception: $exception');
    }

    if (!tester.any(finder)) {
      debugPrint('✔ $stage -> gone');
      return;
    }
  }

  fail(
    '[$stage] Timed out after ${timeout.inSeconds}s waiting for $finder '
    'to disappear.',
  );
}

/// Pumps a single frame and fails fast when the frame throws.
///
/// Bare [WidgetTester.pump] calls let widget exceptions escape into the test
/// zone where they poison the binding and stall the journey; this keeps the
/// [stage] name attached to the failure instead.
Future<void> pumpStage(
  WidgetTester tester, {
  required String stage,
  Duration duration = const Duration(milliseconds: 300),
}) async {
  await tester.pump(duration);
  final exception = tester.takeException();
  if (exception != null) {
    fail('[$stage] Flutter exception: $exception');
  }
}

/// Runs [body] under a named stage so integration-test failures report which
/// step of the journey broke. Failures are re-thrown with a
/// `` `[step:name]` `` prefix; other errors keep their original stack.
Future<T> step<T>(String name, Future<T> Function() body) async {
  debugPrint('▶ $name');
  try {
    return await body();
  } on TestFailure catch (failure) {
    throw TestFailure('[step:$name] ${failure.message}');
  }
}
