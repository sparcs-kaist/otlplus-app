import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/pages/review_page.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/latest_reviews_model.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          ChangeNotifierProvider<HallOfFameModel>.value(
            value: hallOfFameModel,
          ),
          ChangeNotifierProvider<LatestReviewsModel>.value(
            value: latestReviewsModel,
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ko')],
          path: 'assets/translations',
          child: MaterialApp(
            home: _ReviewPageHarness(key: harnessKey),
          ),
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
  _InfoModel() : super(forTest: true);

  @override
  List<Semester> get semesters => const <Semester>[];
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(Dio());

  int hallOfFameCallCount = 0;

  @override
  Future<ReviewListResult> fetchHallOfFame({
    int? year,
    int? semester,
    int offset = 0,
    int limit = 10,
  }) async {
    hallOfFameCallCount++;
    return const ReviewListResult(
      reviews: [],
      averageGrade: 0,
      averageLoad: 0,
      averageSpeech: 0,
      department: null,
      totalCount: 0,
    );
  }
}
