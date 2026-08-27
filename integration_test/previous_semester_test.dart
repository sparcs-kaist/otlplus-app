import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otlplus/main.dart' as app;
import 'package:otlplus/pages/login_page.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/extensions/semester.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/credentials.dart';
import 'support/sso_client.dart';
import 'support/wait_for.dart';

/// Reproduction harness for the "previous semester" error reports: logs in
/// with the real test account, walks EVERY previous semester via the same
/// code path as the SemesterPicker left arrow, and requires each switch to
/// land on a loaded timetable (or the placeholder degrade) instead of the
/// load-failure screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'every previous semester switch lands without the error screen',
    (tester) async {
      await step('sso-clear-vault', () async {
        await StorageService().deleteTokens();
      });

      final tokens = await step(
        'sso-login',
        () => SsoClient().login(
          email: TestCredentials.email,
          password: TestCredentials.password,
        ),
      );

      await step('seed-state', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_consent_shown', true);
        await prefs.setBool('hasAccount', true);
        await StorageService().saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
      });
      addTearDown(() async {
        await StorageService().deleteTokens();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('notification_consent_shown');
        await prefs.remove('hasAccount');
      });

      app.main();

      final launchOutcome = await waitForAny(
        tester,
        <String, Finder>{
          'home': find.byKey(const Key('home_bottom_nav')),
          'login': find.byType(LoginPage),
        },
        stage: 'launch-home',
        timeout: const Duration(seconds: 60),
      );
      if (launchOutcome != 'home') {
        fail('[prev-semester] startup did not restore the session');
      }

      // Switch to the timetable tab so the SemesterPicker tree exists.
      await tester.tap(
        find
            .descendant(
              of: find.byKey(const Key('home_bottom_nav')),
              matching: find.byIcon(Icons.table_chart_outlined),
            )
            .first,
      );
      await tester.pump(const Duration(milliseconds: 600));

      final firstLoad = await waitForAny(
        tester,
        <String, Finder>{
          'loaded': find.byKey(const Key('timetable_loaded')),
          'error': find.byKey(const Key('timetable_error')),
        },
        stage: 'current-semester',
        timeout: const Duration(seconds: 60),
      );
      if (firstLoad != 'loaded') {
        fail('[prev-semester] the CURRENT semester failed to load');
      }

      final model = Provider.of<TimetableModel>(
        tester.element(find.byKey(const Key('home_bottom_nav'))),
        listen: false,
      );
      final infoModel = Provider.of<InfoModel>(
        tester.element(find.byKey(const Key('home_bottom_nav'))),
        listen: false,
      );
      debugPrint(
        '[prev-semester] semesters=${infoModel.semesters.length} '
        'current=${model.selectedSemester.title}',
      );

      if (!model.canGoPreviousSemester) {
        debugPrint(
          '[prev-semester] account has only one semester; nothing to walk',
        );
        return;
      }

      var walked = 0;
      while (model.canGoPreviousSemester) {
        final target = model.selectedSemester;
        debugPrint(
          '[prev-semester] switch #${walked + 1} from '
          '${model.selectedSemester.title}',
        );

        model.goPreviousSemester();

        final outcome = await waitForAny(
          tester,
          <String, Finder>{
            'loaded': find.byKey(const Key('timetable_loaded')),
            'error': find.byKey(const Key('timetable_error')),
          },
          stage: 'switch-to-${target.year}-${target.semester}',
          timeout: const Duration(seconds: 45),
        );

        if (outcome != 'loaded') {
          fail(
            '[prev-semester] switch to ${model.selectedSemester.title} '
            'landed on the error screen. '
            'error=${model.error} '
            'summaries=${model.summaries.length} '
            'timetables=${model.timetables.length} '
            'selectedSemester=${model.selectedSemester.title}',
          );
        }
        walked += 1;
      }
      debugPrint('[prev-semester] walked $walked semesters, all loaded');
    },
    skip: !TestCredentials.available,
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
