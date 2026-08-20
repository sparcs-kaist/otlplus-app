import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/widgets/timetable_mode_control.dart';
import 'package:otlplus/widgets/timetable_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/extensions.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('timetable mode control emits a typed view mode', (tester) async {
    TimetableViewMode? selectedMode;

    await tester.pumpWidget(
      TimetableModeControl(
        selectedMode: TimetableViewMode.classes,
        onTap: (mode) => selectedMode = mode,
      ).scaffold,
    );

    await tester.tap(find.byIcon(Icons.menu_book));

    expect(selectedMode, TimetableViewMode.exams);
  });

  Future<void> expectTabAction(
    WidgetTester tester, {
    required TimetableTabAction expectedAction,
    required IconData actionIcon,
    int selectedTabIndex = 0,
  }) async {
    TimetableTabAction? selectedAction;
    int? selectedIndex;

    await tester.pumpWidget(
      TimetableTabs(
        index: selectedTabIndex,
        length: selectedTabIndex + 1,
        onTap: (_) {},
        onAction: (action, index) {
          selectedAction = action;
          selectedIndex = index;
        },
      ).scaffold,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(actionIcon));
    await tester.pumpAndSettle();

    expect(selectedAction, expectedAction);
    expect(selectedIndex, selectedTabIndex);
  }

  testWidgets('timetable tab menu emits copy action', (tester) async {
    await expectTabAction(
      tester,
      expectedAction: TimetableTabAction.copy,
      actionIcon: Icons.copy,
    );
  });

  testWidgets('timetable tab menu emits image export action', (tester) async {
    await expectTabAction(
      tester,
      expectedAction: TimetableTabAction.exportImage,
      actionIcon: Icons.image_outlined,
    );
  });

  testWidgets('timetable tab menu emits iCal export action', (tester) async {
    await expectTabAction(
      tester,
      expectedAction: TimetableTabAction.exportIcal,
      actionIcon: Icons.calendar_today_outlined,
    );
  });

  testWidgets('timetable tab menu emits delete action and tab index', (
    tester,
  ) async {
    await expectTabAction(
      tester,
      expectedAction: TimetableTabAction.delete,
      actionIcon: Icons.delete_outlined,
      selectedTabIndex: 1,
    );
  });

  test('timetable model stores typed mode and exposes typed season', () {
    final model = TimetableModel(forTest: true);

    expect(model.selectedMode, TimetableViewMode.classes);
    expect(model.selectedSeason, Season.fall);

    model.setMode(TimetableViewMode.map);

    expect(model.selectedMode, TimetableViewMode.map);
  });
}
