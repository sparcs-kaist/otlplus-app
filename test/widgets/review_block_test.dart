import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/services/posthog_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:otlplus/widgets/expandable_text.dart';
import 'package:otlplus/widgets/review_block.dart';
import 'package:otlplus/widgets/telemetry_synchronizer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../utils/extensions.dart';
import '../utils/samples.dart';

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({this.error}) : super(Dio());

  final Object? error;
  ReviewLikeAction? action;
  int? reviewId;

  @override
  Future<int> updateLiked({
    required int reviewId,
    required ReviewLikeAction action,
  }) async {
    this.reviewId = reviewId;
    this.action = action;
    if (error != null) throw error!;
    return reviewId;
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  late UrlLauncherPlatform originalUrlLauncher;
  late _FakeUrlLauncherPlatform urlLauncher;

  setUp(() {
    originalUrlLauncher = UrlLauncherPlatform.instance;
    urlLauncher = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = urlLauncher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalUrlLauncher;
  });

  testWidgets('pump ReviewBlock', (WidgetTester tester) async {
    await tester.pumpWidget(ReviewBlock(review: SampleReview.shared).material);
  });

  testWidgets('test buttons in ReviewBlock', (WidgetTester tester) async {
    await tester.pumpWidget(ReviewBlock(review: SampleReview.shared).material);

    // final likeFinder = find.text('좋아요');
    final reportFinder = find.text('신고하기');

    // expect(likeFinder, findsOneWidget);
    expect(reportFinder, findsOneWidget);
  });

  testWidgets('unlikes a review through the v2 repository', (
    WidgetTester tester,
  ) async {
    final repository = _FakeReviewRepository();
    await tester.pumpWidget(
      Provider<ReviewRepository>.value(
        value: repository,
        child: ReviewBlock(review: SampleReview.shared).material,
      ),
    );

    await tester.tap(find.byIcon(Icons.thumb_up_alt));
    await tester.pump(const Duration(seconds: 1));

    expect(repository.reviewId, SampleReview.id);
    expect(repository.action, ReviewLikeAction.unlike);
  });

  testWidgets('failed unlike rolls back optimistic state without crashing', (
    tester,
  ) async {
    final failure = StateError('update failed');
    final repository = _FakeReviewRepository(error: failure);
    final escapedErrors = <Object>[];
    final review = _reviewWithContent(
      'rollback review content',
      like: 97,
      liked: true,
    );
    await tester.pumpWidget(
      Provider<ReviewRepository>.value(
        value: repository,
        child: ReviewBlock(review: review).material,
      ),
    );

    await runZonedGuarded<Future<void>>(() async {
      await tester.tap(find.byIcon(Icons.thumb_up_alt));
      await tester.pump(const Duration(seconds: 1));
    }, (error, stackTrace) => escapedErrors.add(error));

    expect(escapedErrors, <Object>[failure]);
    expect(find.byIcon(Icons.thumb_up_alt), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText().contains('97') == true,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('report review triggers mailto launch', (tester) async {
    final telemetry = _RecordingTelemetryCoordinator();
    final review = _reviewWithContent('reportable review content');
    await _pumpReviewBlock(tester, review, telemetry);

    await tester.tap(find.text('신고하기'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(urlLauncher.urls, hasLength(1));
    expect(urlLauncher.urls.single, startsWith('mailto:'));
    expect(telemetry.operations, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failing report mailto launch is observed and does not escape', (
    tester,
  ) async {
    urlLauncher.throwOnLaunch = true;
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    final review = _reviewWithContent('reportable review content');
    await _pumpReviewBlock(tester, review, telemetry);

    await runZonedGuarded<Future<void>>(() async {
      await tester.tap(find.text('신고하기'));
      await tester.pump(const Duration(milliseconds: 700));
    }, (error, stackTrace) => escapedErrors.add(error));

    expect(escapedErrors, isEmpty);
    expect(telemetry.operations, <String>['launch_review_report_email']);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ExpandableText &&
            widget.text == 'reportable review content',
      ),
      findsOneWidget,
    );
  });
}

Review _reviewWithContent(
  String content, {
  int? like,
  bool? liked,
}) {
  return Review(
    id: SampleReview.id,
    course: SampleReview.course,
    lecture: SampleReview.lecture,
    content: content,
    like: like ?? SampleReview.like,
    isDeleted: SampleReview.isDeleted,
    grade: SampleReview.grade,
    load: SampleReview.load,
    speech: SampleReview.speech,
    userspecificIsLiked: liked ?? SampleReview.userspecificIsLiked,
  );
}

Future<void> _pumpReviewBlock(
  WidgetTester tester,
  Review review,
  TelemetryCoordinator telemetry,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>.value(
          value: SettingsModel(forTest: true),
        ),
        ChangeNotifierProvider<InfoModel>.value(
          value: InfoModel(forTest: true),
        ),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('ko')],
        path: 'assets/translations',
        child: TelemetrySynchronizer(
          telemetry: telemetry,
          child: MaterialApp(
            home: Scaffold(body: ReviewBlock(review: review)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  final List<String> urls = <String>[];
  bool throwOnLaunch = false;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    if (throwOnLaunch) {
      throw PlatformException(code: 'no_handler');
    }
    return true;
  }
}

class _RecordingTelemetryCoordinator extends TelemetryCoordinator {
  _RecordingTelemetryCoordinator()
    : super(
        analytics: _NoOpAnalyticsClient(),
        crashReporting: _NoOpCrashReportingClient(),
      );

  final List<String> operations = <String>[];

  @override
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) async {
    operations.add(operation);
  }
}

class _NoOpAnalyticsClient implements AnalyticsClient {
  @override
  Future<void> capture(String eventName) async {}

  @override
  Future<void> disable() async {}

  @override
  Future<void> enable() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> reset() async {}
}

class _NoOpCrashReportingClient implements CrashReportingClient {
  @override
  Future<void> deleteUnsentReports() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
    required String reason,
  }) async {}

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserIdentifier(String identifier) async {}
}
