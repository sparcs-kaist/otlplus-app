import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/pages/review_page.dart';
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
