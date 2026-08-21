import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/widgets/review_block.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/extensions.dart';
import '../utils/samples.dart';

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(Dio());

  ReviewLikeAction? action;
  int? reviewId;

  @override
  Future<int> updateLiked({
    required int reviewId,
    required ReviewLikeAction action,
  }) async {
    this.reviewId = reviewId;
    this.action = action;
    return reviewId;
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
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
}
