import "package:dio/dio.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/repositories/review_repository.dart";
import "package:otlplus/widgets/review_write_block.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../utils/extensions.dart";
import "../utils/samples.dart";

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(Dio());

  int? reviewId;
  String? content;
  int? grade;
  int? load;
  int? speech;

  @override
  Future<int> update({
    required int reviewId,
    required String content,
    required int grade,
    required int load,
    required int speech,
  }) async {
    this.reviewId = reviewId;
    this.content = content;
    this.grade = grade;
    this.load = load;
    this.speech = speech;
    return reviewId;
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestWidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets("updates a review through the v2 repository", (
    WidgetTester tester,
  ) async {
    final repository = _FakeReviewRepository();
    var reloadCount = 0;
    await tester.pumpWidget(
      Provider<ReviewRepository>.value(
        value: repository,
        child: ReviewWriteBlock(
          lecture: SampleLecture.shared,
          existingReview: SampleReview.shared,
          onUploaded: () async {
            reloadCount += 1;
          },
        ).scaffold,
      ),
    );

    await tester.enterText(find.byType(EditableText), "updated review");
    await tester.pump();
    await tester.tap(find.text("수정"));
    await tester.pump(const Duration(seconds: 1));

    expect(repository.reviewId, SampleReview.id);
    expect(repository.content, "updated review");
    expect(repository.grade, SampleReview.grade);
    expect(repository.load, SampleReview.load);
    expect(repository.speech, SampleReview.speech);
    expect(reloadCount, 1);
  });
}
