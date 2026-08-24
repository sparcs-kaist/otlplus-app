import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/main.dart' as app;
import 'package:otlplus/models/review.dart';
import 'package:otlplus/pages/login_page.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/credentials.dart';
import 'support/sso_client.dart';
import 'support/wait_for.dart';

/// Exercises the surfaces a logged-in user reaches, against the production
/// OTL backend, using a dedicated Doppler-stored test account.
///
/// The only mutation (updating an existing review) is self-restoring: the
/// original content is written back in a `finally` block and verified through
/// the API. If the account has no review-writable lecture with an existing
/// review, the mutation stage is skipped with a loud log because creating a
/// review could not be undone (the repository exposes no delete); every other
/// stage still asserts.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'logged-in user journey with self-restoring review write',
    (tester) async {
      final marker = 'e2e-${DateTime.now().millisecondsSinceEpoch}';
      var currentStage = 'init';
      Future<T> journey<T>(String name, Future<T> Function() body) async {
        currentStage = name;
        return step(name, body);
      }

      // Unmounting the app cancels its timers so the live binding can
      // finish its completion handshake instead of stalling until timeout.
      Future<void> unmountApp() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Stray asynchronous errors (e.g. an unawaited provider future) poison
      // the integration-test zone and stall the whole journey until the CLI
      // timeout. Contain them here so they fail fast, named, with their
      // original message instead.
      final escapedZoneErrors = <Object>[];

      Future<void> runJourney() async {
        await journey('sso-clear-vault', () async {
          await StorageService().deleteTokens();
        });

        final tokens = await journey(
          'sso-login',
          () => SsoClient().login(
            email: TestCredentials.email,
            password: TestCredentials.password,
          ),
        );

        await journey('seed-state', () async {
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

        await journey('launch', () async {
          app.main();
        });

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
          fail('[launch] startup did not restore the injected session');
        }

        Finder navIcon(IconData icon) => find.descendant(
          of: find.byKey(const Key('home_bottom_nav')),
          matching: find.byIcon(icon),
        );

        // IndexedStack keeps every tab mounted, so taps must be followed by a
        // pump before the freshly active tab is hit-testable.
        Future<void> switchTab(IconData icon, String stage) async {
          await tester.tap(navIcon(icon));
          await pumpStage(tester, stage: stage);
        }

        // The home dashboard renders user-dependent content only after
        // semesters and session info have loaded.
        final infoModel = Provider.of<InfoModel>(
          tester.element(find.byKey(const Key('home_bottom_nav'))),
          listen: false,
        );
        await journey('user-info', () async {
          final deadline = DateTime.now().add(const Duration(seconds: 30));
          while (!infoModel.hasData && DateTime.now().isBefore(deadline)) {
            await pumpStage(
              tester,
              stage: 'user-info',
              duration: const Duration(milliseconds: 100),
            );
          }
        });
        expect(infoModel.hasData, isTrue, reason: '[user-info] never loaded');

        expect(
          find.byKey(const Key('main_user_button')),
          findsOneWidget,
          reason: '[home] account entry point missing',
        );

        await journey(
          'timetable-open',
          () => switchTab(Icons.table_chart_outlined, 'timetable-open'),
        );
        final timetableOutcome = await waitForAny(
          tester,
          <String, Finder>{
            'loaded': find.byKey(const Key('timetable_loaded')),
            'error': find.byKey(const Key('timetable_error')),
          },
          stage: 'timetable',
          timeout: const Duration(seconds: 60),
        );
        // Reaching the tab is the contract; whether the shared test account
        // has a current-semester timetable is account data, not app behavior.
        if (timetableOutcome != 'loaded') {
          debugPrint(
            '[timetable] account has no loadable current timetable; continuing',
          );
        }

        await journey(
          'dictionary-open',
          () => switchTab(Icons.library_books_outlined, 'dictionary-open'),
        );
        final hintFinder = _firstPresent(tester, [
          find.textContaining('과목명, 교수님 성함 등을 검색해 보세요.'),
          find.textContaining('Search by course title'),
        ]);
        await waitForAny(
          tester,
          <String, Finder>{'hint': hintFinder!},
          stage: 'dictionary-hint',
          timeout: const Duration(seconds: 30),
        );

        await journey('search-open', () => tester.tap(hintFinder));
        await waitForAny(
          tester,
          <String, Finder>{'field': find.byType(TextField).first},
          stage: 'search-field',
          timeout: const Duration(seconds: 30),
        );
        await journey('search-submit', () async {
          await tester.enterText(find.byType(TextField).first, 'CS320');
          await pumpStage(tester, stage: currentStage);

          final searchButton = _firstPresent(tester, [
            find.text('Search'),
            find.text('검색'),
          ]);
          expect(searchButton, isNotNull, reason: '[search] button not found');
          await tester.tap(searchButton!);
          await pumpStage(tester, stage: currentStage);

          // The dictionary list lives in an IndexedStack below the pushed
          // search page, so it can become findable before the page closes;
          // wait for the close first or later taps would hit covered widgets.
          await waitUntilGone(
            tester,
            find.byType(TextField),
            stage: 'search-close',
            timeout: const Duration(seconds: 60),
          );
        });

        final searchOutcome = await waitForAny(
          tester,
          <String, Finder>{
            'results': find.byKey(const Key('dictionary_list')),
            'empty': _firstPresent(tester, [
              find.text('No result.'),
              find.text('검색 결과가 없습니다.'),
            ])!,
          },
          stage: 'search-results',
          timeout: const Duration(seconds: 60),
        );
        debugPrint('[search-results] $searchOutcome');

        await journey(
          'review-feed-open',
          () => switchTab(Icons.rate_review_outlined, 'review-feed-open'),
        );
        await waitForAny(
          tester,
          <String, Finder>{'list': find.byKey(const Key('review_list'))},
          stage: 'review-feed',
          timeout: const Duration(seconds: 60),
        );

        await switchTab(Icons.home_outlined, 'home-tab');
        await journey('user-page-open', () {
          return tester.tap(find.byKey(const Key('main_user_button')));
        });
        var openRoutes = 1;
        await waitForAny(
          tester,
          <String, Finder>{
            'user': find.byKey(const Key('user_my_review_button')),
          },
          stage: 'user-page',
          timeout: const Duration(seconds: 30),
        );

        Review? originalReview;
        for (final lecture in infoModel.user.reviewWritableLectures) {
          for (final review in infoModel.user.reviews) {
            if (review.lecture.id == lecture.id) {
              originalReview = review;
              break;
            }
          }
          if (originalReview != null) break;
        }
        final targetLecture = infoModel.user.reviewWritableLectures.where((
          lecture,
        ) {
          return lecture.id == originalReview?.lecture.id;
        }).firstOrNull;
        final canMutate = originalReview != null && targetLecture != null;
        if (!canMutate) {
          debugPrint(
            '[review-write] skipped: no review-writable lecture with an '
            'existing review on this account; creating one would not be '
            'self-restoring.',
          );
        }

        if (canMutate) {
          await journey('my-reviews-open', () {
            return tester.tap(find.byKey(const Key('user_my_review_button')));
          });
          openRoutes += 1;
          final lectureBlockFinder = find.textContaining(targetLecture.title);
          await waitForAny(
            tester,
            <String, Finder>{'lecture': lectureBlockFinder.first},
            stage: 'my-reviews',
            timeout: const Duration(seconds: 60),
          );
          await journey('lecture-detail-open', () async {
            await tester.ensureVisible(lectureBlockFinder.first);
            await pumpStage(tester, stage: currentStage);
            await tester.tap(lectureBlockFinder.first);
          });
          openRoutes += 1;

          await journey('review-editor-wait', () async {
            final field = find.byKey(const Key('review_write_field'));
            final deadline = DateTime.now().add(const Duration(seconds: 45));
            while (field.evaluate().isEmpty &&
                DateTime.now().isBefore(deadline)) {
              await pumpStage(
                tester,
                stage: 'review-editor',
                duration: const Duration(milliseconds: 100),
              );
            }
          });
          expect(
            find.byKey(const Key('review_write_field')).evaluate(),
            isNotEmpty,
            reason: '[review-write] editor never appeared',
          );

          try {
            await journey('review-write-submit', () async {
              final field = find.byKey(const Key('review_write_field')).first;
              await tester.ensureVisible(field);
              await tester.enterText(field, marker);
              await pumpStage(tester, stage: currentStage);

              final submit = find.byKey(const Key('review_write_submit')).first;
              await tester.ensureVisible(submit);
              await tester.tap(submit);
            });

            final uploadOutcome = await waitForAny(
              tester,
              <String, Finder>{
                'updated': find.textContaining(marker),
                'failed': find.textContaining('저장하지 못했습니다'),
                'failed-en': find.textContaining('Failed to save review'),
              },
              stage: 'review-upload',
              timeout: const Duration(seconds: 60),
            );
            expect(uploadOutcome, 'updated');
          } finally {
            // Restore the original review whenever submission may have
            // happened; an update with identical values is harmless.
            final restoredOriginal = originalReview;
            await journey('review-restore', () {
              return ReviewRepository(DioProvider().dio).update(
                reviewId: restoredOriginal.id,
                content: restoredOriginal.content,
                grade: restoredOriginal.grade,
                load: restoredOriginal.load,
                speech: restoredOriginal.speech,
              );
            });
            final detailResponse = await journey(
              'review-restore-verify',
              () => DioProvider().dio.get(
                'api/v2/reviews/${restoredOriginal.id}',
              ),
            );
            final detail =
                (detailResponse.data ?? <String, dynamic>{})
                    as Map<String, dynamic>;
            expect(detail['content'], restoredOriginal.content);
            expect(detail['grade'], restoredOriginal.grade);
            expect(detail['load'], restoredOriginal.load);
            expect(detail['speech'], restoredOriginal.speech);
          }
        }

        // Visit liked reviews from the account page.
        while (openRoutes > 1) {
          tester.state<NavigatorState>(find.byType(Navigator).first).pop();
          await pumpStage(tester, stage: currentStage);
          openRoutes -= 1;
        }
        await journey('liked-reviews-open', () {
          return tester.tap(find.byKey(const Key('user_liked_review_button')));
        });
        openRoutes += 1;
        final likedTitleFinder = _firstPresent(tester, [
          find.textContaining('좋아요한 후기'),
          find.textContaining('Liked Reviews'),
        ]);
        await waitForAny(
          tester,
          <String, Finder>{'liked': likedTitleFinder!},
          stage: 'liked-reviews',
          timeout: const Duration(seconds: 30),
        );

        while (openRoutes > 0) {
          tester.state<NavigatorState>(find.byType(Navigator).first).pop();
          await pumpStage(tester, stage: currentStage);
          openRoutes -= 1;
        }

        await journey('logout-open', () {
          return tester.tap(find.byKey(const Key('main_user_button')));
        });
        await waitForAny(
          tester,
          <String, Finder>{
            'logout': find.byKey(const Key('user_logout_button')),
          },
          stage: 'logout-button',
          timeout: const Duration(seconds: 30),
        );
        await journey('logout-tap', () {
          return tester.tap(find.byKey(const Key('user_logout_button')));
        });

        final logoutOutcome = await waitForAny(
          tester,
          <String, Finder>{'login': find.byType(LoginPage)},
          stage: 'logout',
          timeout: const Duration(seconds: 30),
        );
        expect(logoutOutcome, 'login');
        await unmountApp();
      }

      await runZonedGuarded(runJourney, (error, stackTrace) {
        debugPrint('[journey-zone-error @ $currentStage] $error');
        escapedZoneErrors.add(error);
      });
      await unmountApp();
      if (escapedZoneErrors.isNotEmpty) {
        fail(
          '[journey] failed at stage [$currentStage]: '
          '${escapedZoneErrors.first}',
        );
      }
    },
    // CI preflight fails loudly when the Doppler config is missing the
    // credentials; forks without secrets simply skip this journey.
    skip: !TestCredentials.available,
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

Finder? _firstPresent(WidgetTester tester, List<Finder> candidates) {
  for (final candidate in candidates) {
    if (tester.any(candidate)) return candidate;
  }
  return null;
}
