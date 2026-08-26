import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/pages/review_page.dart';
import 'package:otlplus/widgets/expandable_text.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/latest_reviews_model.dart';
import 'package:otlplus/repositories/info_repository.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/samples.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('ReviewPage loads explicitly and owns its scroll controller', (
    tester,
  ) async {
    final repository = _FakeReviewRepository();
    final hallOfFameModel = HallOfFameModel(repository);
    final latestReviewsModel = LatestReviewsModel(repository);
    final harnessKey = GlobalKey<_ReviewPageHarnessState>();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<InfoModel>.value(value: _InfoModel()),
          ChangeNotifierProvider<HallOfFameModel>.value(value: hallOfFameModel),
          ChangeNotifierProvider<LatestReviewsModel>.value(
            value: latestReviewsModel,
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ko')],
          path: 'assets/translations',
          child: MaterialApp(home: _ReviewPageHarness(key: harnessKey)),
        ),
      ),
    );
    await tester.pump();

    expect(repository.hallOfFameCallCount, 1);
    final scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    final controller = scrollView.controller!;
    expect(controller.hasClients, isTrue);

    harnessKey.currentState!.hideReviewPage();
    await tester.pump();

    expect(() => controller.addListener(() {}), throwsFlutterError);
  });

  testWidgets('latest reviews delegate ignores a stale out-of-range index', (
    tester,
  ) async {
    final repository = _FakeReviewRepository(
      recentReviews: <Review>[SampleReview.shared],
    );
    final hallOfFameModel = HallOfFameModel(repository)
      ..setMode(ReviewTab.latest);
    final latestReviewsModel = LatestReviewsModel(repository);

    await _pumpReviewPage(
      tester,
      hallOfFameModel: hallOfFameModel,
      latestReviewsModel: latestReviewsModel,
    );

    final reviewsLength = latestReviewsModel.latestReviews.length;
    final sliver = tester.widget<SliverList>(find.byType(SliverList));
    final delegate = sliver.delegate as SliverChildBuilderDelegate;

    expect(
      delegate.builder(
        tester.element(find.byType(CustomScrollView)),
        reviewsLength,
      ),
      isNull,
    );
  });

  testWidgets('hall of fame delegate ignores a stale out-of-range index', (
    tester,
  ) async {
    final repository = _FakeReviewRepository(
      recentReviews: <Review>[SampleReview.shared],
      hallOfFameReviews: <Review>[SampleReview.shared],
    );
    final hallOfFameModel = HallOfFameModel(repository)
      ..setMode(ReviewTab.latest);
    final latestReviewsModel = LatestReviewsModel(repository);

    await _pumpReviewPage(
      tester,
      hallOfFameModel: hallOfFameModel,
      latestReviewsModel: latestReviewsModel,
    );
    hallOfFameModel.setMode(ReviewTab.hallOfFame);
    await hallOfFameModel.load();
    await tester.pump();

    final reviewsLength = hallOfFameModel.hallOfFame.length;
    final sliver = tester.widget<SliverList>(find.byType(SliverList));
    final delegate = sliver.delegate as SliverChildBuilderDelegate;

    expect(
      delegate.builder(
        tester.element(find.byType(CustomScrollView)),
        reviewsLength,
      ),
      isNull,
    );
  });

  testWidgets('hall of fame feed keeps paginating until the last page', (
    tester,
  ) async {
    final repository = _PagingReviewRepository(
      totalRecent: 0,
      totalHallOfFame: 25,
    );
    final hallOfFameModel = HallOfFameModel(repository);
    final latestReviewsModel = LatestReviewsModel(repository);

    await tester.pumpWidget(_pumpablePage(hallOfFameModel, latestReviewsModel));
    await tester.pumpAndSettle();

    expect(repository.hallOfFameOffsets, [0]);
    expect(_richTextContaining('hof-content-0'), findsOneWidget);

    for (var drag = 0; drag < 12; drag++) {
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -1200),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
    }

    expect(
      repository.hallOfFameOffsets,
      [0, 10, 20],
      reason: 'scrolling to the bottom must keep fetching next pages',
    );
    expect(_richTextContaining('hof-content-24'), findsOneWidget);
  });

  testWidgets(
    'an empty page stops pagination even when totalCount overpromises',
    (tester) async {
      final repository = _PagingReviewRepository(
        totalRecent: 0,
        totalHallOfFame: 40,
        serverItemCap: 20,
      );
      final hallOfFameModel = HallOfFameModel(repository);
      final latestReviewsModel = LatestReviewsModel(repository);

      await tester.pumpWidget(
        _pumpablePage(hallOfFameModel, latestReviewsModel),
      );
      await tester.pumpAndSettle();

      for (var drag = 0; drag < 12; drag++) {
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -1200),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
      }

      expect(
        repository.hallOfFameOffsets,
        [0, 10, 20],
        reason:
            'after the server returns an empty page, pagination must stop '
            'instead of refiring forever at the same scroll position',
      );
      expect(hallOfFameModel.hasMore, isFalse);
      expect(_richTextContaining('hof-content-19'), findsOneWidget);
    },
  );

  testWidgets('latest feed keeps paginating until the last page', (
    tester,
  ) async {
    final repository = _PagingReviewRepository(totalRecent: 25);
    final hallOfFameModel = HallOfFameModel(repository)
      ..setMode(ReviewTab.latest);
    final latestReviewsModel = LatestReviewsModel(repository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<InfoModel>.value(value: _InfoModel()),
          ChangeNotifierProvider<HallOfFameModel>.value(value: hallOfFameModel),
          ChangeNotifierProvider<LatestReviewsModel>.value(
            value: latestReviewsModel,
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ko')],
          path: 'assets/translations',
          child: const MaterialApp(home: Scaffold(body: ReviewPage())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.recentOffsets, [0]);
    expect(_richTextContaining('paging-content-0'), findsOneWidget);

    for (var drag = 0; drag < 12; drag++) {
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -1200),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
    }

    expect(
      repository.recentOffsets,
      [0, 10, 20],
      reason: 'scrolling to the bottom must keep fetching next pages',
    );
    expect(_richTextContaining('paging-content-24'), findsOneWidget);
  });
}

Future<void> _pumpReviewPage(
  WidgetTester tester, {
  required HallOfFameModel hallOfFameModel,
  required LatestReviewsModel latestReviewsModel,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<InfoModel>.value(value: _InfoModel()),
        ChangeNotifierProvider<HallOfFameModel>.value(value: hallOfFameModel),
        ChangeNotifierProvider<LatestReviewsModel>.value(
          value: latestReviewsModel,
        ),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('ko')],
        path: 'assets/translations',
        child: const MaterialApp(home: Scaffold(body: ReviewPage())),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

class _ReviewPageHarness extends StatefulWidget {
  const _ReviewPageHarness({super.key});

  @override
  State<_ReviewPageHarness> createState() => _ReviewPageHarnessState();
}

class _ReviewPageHarnessState extends State<_ReviewPageHarness> {
  bool _showReviewPage = true;

  void hideReviewPage() {
    setState(() => _showReviewPage = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showReviewPage ? const ReviewPage() : const SizedBox.shrink(),
    );
  }
}

class _InfoModel extends InfoModel {
  _InfoModel() : super(infoRepository: InfoRepository(Dio()), forTest: true);

  @override
  List<Semester> get semesters => const <Semester>[];
}

Widget _pumpablePage(
  HallOfFameModel hallOfFameModel,
  LatestReviewsModel latestReviewsModel,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<InfoModel>.value(value: _InfoModel()),
      ChangeNotifierProvider<HallOfFameModel>.value(value: hallOfFameModel),
      ChangeNotifierProvider<LatestReviewsModel>.value(
        value: latestReviewsModel,
      ),
    ],
    child: EasyLocalization(
      supportedLocales: const [Locale('ko')],
      path: 'assets/translations',
      child: const MaterialApp(home: Scaffold(body: ReviewPage())),
    ),
  );
}

Finder _richTextContaining(String pattern) {
  return find.byWidgetPredicate(
    (widget) => widget is ExpandableText && widget.text.contains(pattern),
  );
}

class _PagingReviewRepository extends ReviewRepository {
  _PagingReviewRepository({
    required this.totalRecent,
    this.totalHallOfFame = 0,
    this.serverItemCap,
  }) : super(Dio());

  final int totalRecent;
  final int totalHallOfFame;

  /// When set, the fake server stops returning items past this many even
  /// though totalCount still advertises the full amount (reproduces the
  /// production mismatch that stalls infinite scroll).
  final int? serverItemCap;
  final List<int> recentOffsets = <int>[];
  final List<int> hallOfFameOffsets = <int>[];

  @override
  Future<ReviewListResult> fetchRecent({
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) async {
    recentOffsets.add(offset);
    final available = serverItemCap == null
        ? totalRecent
        : (serverItemCap! < totalRecent ? serverItemCap! : totalRecent);
    final end = (offset + limit) > available ? available : offset + limit;
    final start = offset > end ? end : offset;
    return ReviewListResult(
      reviews: [
        for (var index = start; index < end; index++)
          Review(
            id: 1000 + index,
            course: SampleReview.course,
            lecture: SampleReview.lecture,
            content: 'paging-content-$index',
            like: 0,
            isDeleted: SampleReview.isDeleted,
            grade: SampleReview.grade,
            load: SampleReview.load,
            speech: SampleReview.speech,
            userspecificIsLiked: false,
          ),
      ],
      averageGrade: 0,
      averageLoad: 0,
      averageSpeech: 0,
      department: null,
      totalCount: totalRecent,
    );
  }

  @override
  Future<ReviewListResult> fetchHallOfFame({
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) async {
    hallOfFameOffsets.add(offset);
    final available = serverItemCap == null
        ? totalHallOfFame
        : (serverItemCap! < totalHallOfFame ? serverItemCap! : totalHallOfFame);
    final end = (offset + limit) > available ? available : offset + limit;
    final start = offset > end ? end : offset;
    return ReviewListResult(
      reviews: [
        for (var index = start; index < end; index++)
          Review(
            id: 2000 + index,
            course: SampleReview.course,
            lecture: SampleReview.lecture,
            content: 'hof-content-$index',
            like: 0,
            isDeleted: SampleReview.isDeleted,
            grade: SampleReview.grade,
            load: SampleReview.load,
            speech: SampleReview.speech,
            userspecificIsLiked: false,
          ),
      ],
      averageGrade: 0,
      averageLoad: 0,
      averageSpeech: 0,
      department: null,
      totalCount: totalHallOfFame,
    );
  }
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({
    this.recentReviews = const <Review>[],
    this.hallOfFameReviews = const <Review>[],
  }) : super(Dio());

  final List<Review> recentReviews;
  final List<Review> hallOfFameReviews;
  int hallOfFameCallCount = 0;

  @override
  Future<ReviewListResult> fetchRecent({
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) async {
    return ReviewListResult(
      reviews: recentReviews,
      averageGrade: 0,
      averageLoad: 0,
      averageSpeech: 0,
      department: null,
      totalCount: recentReviews.length,
    );
  }

  @override
  Future<ReviewListResult> fetchHallOfFame({
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) async {
    hallOfFameCallCount++;
    return ReviewListResult(
      reviews: hallOfFameReviews,
      averageGrade: 0,
      averageLoad: 0,
      averageSpeech: 0,
      department: null,
      totalCount: hallOfFameReviews.length,
    );
  }
}
