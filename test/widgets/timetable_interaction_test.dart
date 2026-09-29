import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/pages/timetable_page.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/repositories/department_repository.dart';
import 'package:otlplus/repositories/lecture_repository.dart';
import 'package:otlplus/repositories/timetable_repository.dart';
import 'package:otlplus/widgets/semester_picker.dart';
import 'package:otlplus/widgets/timetable_mode_control.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/extensions.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final direction in ui.TextDirection.values) {
    testWidgets(
      'mode highlight matches every button in $direction with a large icon theme',
      (tester) async {
        for (final mode in TimetableViewMode.values) {
          TimetableViewMode? tapped;
          await tester.pumpWidget(
            Directionality(
              textDirection: direction,
              child: IconTheme(
                data: const IconThemeData(size: 32),
                child: Center(
                  child: TimetableModeControl(
                    selectedMode: mode,
                    onTap: (value) => tapped = value,
                  ),
                ),
              ),
            ).scaffold,
          );
          await tester.pumpAndSettle();
          final icon = [
            Icons.schedule,
            Icons.menu_book,
            Icons.map_outlined,
          ][mode.index];
          final indicator = find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color ==
                    OTLColor.pinksMain,
          );
          expect(
            tester.getCenter(find.byIcon(icon)).dx,
            closeTo(tester.getCenter(indicator).dx, 0.1),
          );
          await tester.tap(find.byIcon(icon));
          expect(tapped, mode);
        }
      },
    );
  }

  testWidgets(
    'semester arrows and mode buttons never overlap on a narrow scaled screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = TimetableModel(
        repository: TimetableRepository(Dio()),
        forTest: true,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TimetableModel>.value(value: model),
            ChangeNotifierProvider(
              create: (_) => LectureSearchModel(
                LectureRepository(Dio()),
                DepartmentRepository(Dio()),
              ),
            ),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: TimetablePage(),
          ).scaffold,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final semester = tester.getRect(find.byType(SemesterPicker));
      final mode = tester.getRect(find.byType(TimetableModeControl));
      expect(
        semester.overlaps(mode),
        isFalse,
        reason:
            'The next-semester arrow must not sit underneath the view buttons',
      );
      for (final label in [
        'timetable.days.mon'.tr(),
        'timetable.summary.credit'.tr(),
      ]) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text(label),
            matching: find.byType(RichText),
          ),
        );
        expect(
          paragraph.size.height,
          greaterThanOrEqualTo(
            paragraph.getMaxIntrinsicHeight(paragraph.size.width) - 0.1,
          ),
          reason: '$label must not be vertically clipped',
        );
      }
      for (final icon in [
        Icons.schedule,
        Icons.menu_book,
        Icons.map_outlined,
      ]) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();
      }
      expect(model.selectedMode, TimetableViewMode.map);
    },
  );
}
