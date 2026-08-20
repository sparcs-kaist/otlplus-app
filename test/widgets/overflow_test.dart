import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/widgets/dropdown.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/widgets/pop_up.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _smallViewport = Size(320, 480);
const _wideViewport = Size(800, 600);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget home, {
    Size size = _smallViewport,
    double textScale = 1.3,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: home,
      ),
    );
  }

  void expectInsideViewport(Rect bounds, Size viewport) {
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(viewport.width));
    expect(bounds.bottom, lessThanOrEqualTo(viewport.height));
  }

  Finder dialogSurface() {
    return find
        .descendant(
          of: find.byType(OTLDialog),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ConstrainedBox && widget.constraints.maxWidth == 256,
          ),
        )
        .first;
  }

  Future<void> openPopUp(
    WidgetTester tester, {
    Size size = _smallViewport,
  }) async {
    await pumpScreen(
      tester,
      Builder(
        builder: (context) {
          return TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const PopUp(),
            ),
            child: const Text('Open'),
          );
        },
      ),
      size: size,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> openDropdown(
    WidgetTester tester, {
    Size size = _smallViewport,
  }) async {
    const dropdownButtonKey = Key('dropdown-button');

    await pumpScreen(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: Dropdown<int>(
            customButton: const Padding(
              key: dropdownButtonKey,
              padding: EdgeInsets.all(16),
              child: Text('Open dropdown'),
            ),
            items: [
              ItemData(
                value: 1,
                text:
                    'An intentionally long dropdown option that must fit on '
                    'a small screen',
                icon: Icons.check,
              ),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
      size: size,
    );

    await tester.tap(find.byKey(dropdownButtonKey));
    await tester.pumpAndSettle();
  }

  testWidgets('OTLDialog fits a small screen with scaled text', (tester) async {
    await pumpScreen(
      tester,
      const OTLDialog(
        type: OTLDialogType.addOverlappingLectureWithTab,
        namedArgs: {
          'lectures':
              "'Computer Science Project', 'Introduction to Algorithms', "
              "'Advanced Programming'",
          'lecture': 'Special Topics in Computer Science',
          'timetable': 'Spring Semester Main Timetable',
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expectInsideViewport(tester.getRect(dialogSurface()), _smallViewport);
  });

  testWidgets('OTLDialog preserves its normal width on wide screens', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const OTLDialog(type: OTLDialogType.resetSettings),
      size: _wideViewport,
      textScale: 1,
    );

    await tester.pumpAndSettle();

    expect(tester.getSize(dialogSurface()).width, 256);
  });

  testWidgets('PopUp fits and keeps its aspect ratio on a small screen', (
    tester,
  ) async {
    await openPopUp(tester);

    final imageBounds = tester.getRect(find.byType(Image).first);
    final buttonBounds = tester.getRect(find.byType(FilledButton).first);

    expect(tester.takeException(), isNull);
    expectInsideViewport(imageBounds, _smallViewport);
    expectInsideViewport(buttonBounds, _smallViewport);
    expect(imageBounds.width / imageBounds.height, closeTo(285 / 328, 0.001));
    expect(buttonBounds.top, greaterThanOrEqualTo(imageBounds.top));
    expect(buttonBounds.bottom, lessThanOrEqualTo(imageBounds.bottom));
  });

  testWidgets('PopUp preserves its normal dimensions on wide screens', (
    tester,
  ) async {
    await openPopUp(tester, size: _wideViewport);

    expect(tester.getSize(find.byType(Image).first), const Size(285, 328));
  });

  testWidgets('Dropdown menu fits a small screen with scaled text', (
    tester,
  ) async {
    await openDropdown(tester);

    final menuItem = find.byType(DropdownItem<int>);

    expect(tester.takeException(), isNull);
    expectInsideViewport(tester.getRect(menuItem), _smallViewport);
  });

  testWidgets('Dropdown preserves its normal width on wide screens', (
    tester,
  ) async {
    await openDropdown(tester, size: _wideViewport);

    expect(tester.getSize(find.byType(DropdownItem<int>)).width, 200);
  });
}
