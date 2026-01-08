import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/widgets/review_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/extensions.dart';
import '../utils/samples.dart';

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
}
