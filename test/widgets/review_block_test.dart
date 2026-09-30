import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/repositories/info_repository.dart';
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
  _FakeReviewRepository({this.error, this.pending}) : super(Dio());

  Object? error;
  Completer<int>? pending;
  int calls = 0;
  ReviewLikeAction? action;
  int? reviewId;

  @override
  Future<int> updateLiked({
    required int reviewId,
    required ReviewLikeAction action,
  }) async {
    this.reviewId = reviewId;
    this.action = action;
    calls++;
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
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
    final options = RequestOptions(path: '/reviews/1/liked');
    final failure = DioException.badResponse(
      statusCode: 400,
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 400),
    );
    final repository = _FakeReviewRepository(error: failure);
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    final review = _reviewWithContent(
      'rollback review content',
      like: 97,
      liked: true,
    );
    await _pumpReviewBlock(tester, review, telemetry, repository: repository);

    await runZonedGuarded<Future<void>>(() async {
      await tester.tap(find.byIcon(Icons.thumb_up_alt));
      await tester.pump(const Duration(seconds: 1));
    }, (error, stackTrace) => escapedErrors.add(error));

    expect(escapedErrors, isEmpty);
    expect(telemetry.operations, ['update_review_like']);
    expect(find.text('좋아요를 변경하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
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

    repository.error = null;
    await tester.tap(find.byIcon(Icons.thumb_up_alt));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
  });

  testWidgets('replacement review uses its own like state and action', (
    tester,
  ) async {
    final repository = _FakeReviewRepository();
    Future<void> show(Review review) => tester.pumpWidget(
      Provider<ReviewRepository>.value(
        value: repository,
        child: ReviewBlock(review: review).scaffold,
      ),
    );
    await show(_reviewWithContent('first', liked: true));
    await show(
      _reviewWithContent('second', id: SampleReview.id + 1, liked: false),
    );
    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined));
    await tester.pump(const Duration(seconds: 1));
    expect(repository.reviewId, SampleReview.id + 1);
    expect(repository.action, ReviewLikeAction.like);
  });

  testWidgets('refresh of the same review updates its server like state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ReviewBlock(review: _reviewWithContent('before', liked: true)).scaffold,
    );
    await tester.pumpWidget(
      ReviewBlock(review: _reviewWithContent('after', liked: false)).scaffold,
    );
    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
  });

  testWidgets('pending failure after removal is observed without escaping', (
    tester,
  ) async {
    final telemetry = _RecordingTelemetryCoordinator();
    final escapedErrors = <Object>[];
    await runZonedGuarded<Future<void>>(() async {
      final pending = Completer<int>();
      final repository = _FakeReviewRepository(pending: pending);
      await _pumpReviewBlock(
        tester,
        SampleReview.shared,
        telemetry,
        repository: repository,
      );
      await tester.tap(find.byIcon(Icons.thumb_up_alt));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      pending.completeError(StateError('late failure'));
      await tester.pump();
    }, (error, stack) => escapedErrors.add(error));
    expect(escapedErrors, isEmpty);
    expect(telemetry.operations, ['update_review_like']);
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

  testWidgets('failed like with expired session rolls back and is observed', (
    tester,
  ) async {
    final options = RequestOptions(path: '/reviews/1/liked');
    final repository = _FakeReviewRepository(
      error: DioException.badResponse(
        statusCode: 401,
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      ),
    );
    final telemetry = _RecordingTelemetryCoordinator();
    await _pumpReviewBlock(
      tester,
      _reviewWithContent('expired session', liked: false),
      telemetry,
      repository: repository,
    );
    await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
    expect(telemetry.operations, ['update_review_like']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'old request cannot roll back a replacement review or block its button',
    (tester) async {
      final pending = Completer<int>();
      final repository = _FakeReviewRepository(pending: pending);
      final selected = ValueNotifier(_reviewWithContent('first', liked: true));
      addTearDown(selected.dispose);
      await tester.pumpWidget(
        Provider<ReviewRepository>.value(
          value: repository,
          child: ValueListenableBuilder<Review>(
            valueListenable: selected,
            builder: (_, review, __) => ReviewBlock(review: review),
          ).scaffold,
        ),
      );
      await tester.tap(find.byIcon(Icons.thumb_up_alt));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined));
      await tester.pump(const Duration(seconds: 1));
      expect(repository.calls, 1);
      selected.value = _reviewWithContent(
        'second',
        id: SampleReview.id + 1,
        liked: false,
      );
      await tester.pump();
      pending.completeError(StateError('old request failed'));
      await tester.pump();
      expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      repository.pending = null;
      await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined));
      await tester.pump(const Duration(seconds: 1));
      expect(repository.calls, 2);
      expect(repository.reviewId, SampleReview.id + 1);
      expect(repository.action, ReviewLikeAction.like);
      expect(find.byIcon(Icons.thumb_up_alt), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

Review _reviewWithContent(String content, {int? id, int? like, bool? liked}) {
  return Review(
    id: id ?? SampleReview.id,
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
  TelemetryCoordinator telemetry, {
  ReviewRepository? repository,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        if (repository != null)
          Provider<ReviewRepository>.value(value: repository),
        ChangeNotifierProvider<SettingsModel>.value(
          value: SettingsModel(forTest: true),
        ),
        ChangeNotifierProvider<InfoModel>.value(
          value: InfoModel(
            infoRepository: InfoRepository(Dio()),
            forTest: true,
          ),
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
  Future<void> identify(String distinctId) async {}

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
