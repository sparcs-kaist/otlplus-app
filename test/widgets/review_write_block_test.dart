import "package:dio/dio.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/color.dart";
import "package:otlplus/repositories/review_repository.dart";
import "package:otlplus/widgets/responsive_button.dart";
import "package:otlplus/widgets/review_write_block.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../utils/extensions.dart";
import "../utils/samples.dart";

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({this.failure}) : super(Dio());

  final Object? failure;
  int? reviewId;
  Map<String, Object>? payload;

  @override
  Future<int> update({
    required int reviewId,
    required String content,
    required int grade,
    required int load,
    required int speech,
  }) async {
    if (failure != null) throw failure!;

    this.reviewId = reviewId;
    payload = <String, Object>{
      "content": content,
      "grade": grade,
      "load": load,
      "speech": speech,
    };
    return reviewId;
  }
}

Finder _scoreRow(String title) {
  return find.ancestor(of: find.text(title), matching: find.byType(Row)).first;
}

Finder _scoreButton(String title, String label) {
  return find.descendant(of: _scoreRow(title), matching: find.text(label));
}

String _selectedScoreLabel(WidgetTester tester, String title) {
  const labels = <String>["A", "B", "C", "D", "F"];
  final buttons = tester
      .widgetList<BackgroundButton>(
        find.descendant(
          of: _scoreRow(title),
          matching: find.byType(BackgroundButton),
        ),
      )
      .toList();
  final selectedIndex = buttons.indexWhere(
    (button) => button.color == OTLColor.gray75,
  );

  return labels[selectedIndex];
}

IconTextButton _submitButton(WidgetTester tester) {
  return tester.widget<IconTextButton>(
    find.byKey(const Key("review_write_submit")),
  );
}

Future<void> _pumpReviewWriteBlock(
  WidgetTester tester, {
  required _FakeReviewRepository repository,
  Future<void> Function()? onUploaded,
}) async {
  await tester.pumpWidget(
    Provider<ReviewRepository>.value(
      value: repository,
      child: ReviewWriteBlock(
        lecture: SampleLecture.shared,
        existingReview: SampleReview.shared,
        onUploaded: onUploaded,
      ).scaffold,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestWidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets("renders the current score letter choices in every row", (
    WidgetTester tester,
  ) async {
    await _pumpReviewWriteBlock(tester, repository: _FakeReviewRepository());

    for (final title in <String>["성적", "널널", "강의"]) {
      expect(_scoreButton(title, "?"), findsNothing);
      for (final label in <String>["F", "D", "C", "B", "A"]) {
        expect(_scoreButton(title, label), findsOneWidget);
      }
    }
  });

  testWidgets("prefills grade, load, and speech from the existing review", (
    WidgetTester tester,
  ) async {
    await _pumpReviewWriteBlock(tester, repository: _FakeReviewRepository());

    expect(_selectedScoreLabel(tester, "성적"), "F");
    expect(_selectedScoreLabel(tester, "널널"), "D");
    expect(_selectedScoreLabel(tester, "강의"), "C");
  });

  testWidgets(
    "enables submit only when content differs and every score is selected",
    (WidgetTester tester) async {
      await _pumpReviewWriteBlock(tester, repository: _FakeReviewRepository());

      expect(_submitButton(tester).onTap, isNull);

      await tester.enterText(find.byType(EditableText), "updated review");
      await tester.pump();
      expect(_submitButton(tester).onTap, isNotNull);

      await tester.tap(_scoreButton("성적", "F"));
      await tester.pump(const Duration(milliseconds: 700));
      expect(_submitButton(tester).onTap, isNull);

      await tester.tap(_scoreButton("성적", "F"));
      await tester.pump(const Duration(milliseconds: 700));
      expect(_submitButton(tester).onTap, isNotNull);

      await tester.enterText(find.byType(EditableText), SampleReview.content);
      await tester.pump();
      expect(_submitButton(tester).onTap, isNull);
    },
  );

  testWidgets("passes the exact integer score payload to the repository", (
    WidgetTester tester,
  ) async {
    final repository = _FakeReviewRepository();
    var reloadCount = 0;
    await _pumpReviewWriteBlock(
      tester,
      repository: repository,
      onUploaded: () async {
        reloadCount += 1;
      },
    );

    await tester.enterText(find.byType(EditableText), "updated review");
    await tester.pump();
    await tester.tap(find.byKey(const Key("review_write_submit")));
    await tester.pump(const Duration(milliseconds: 700));

    expect(repository.reviewId, SampleReview.id);
    expect(repository.payload, <String, Object>{
      "content": "updated review",
      "grade": SampleReview.grade,
      "load": SampleReview.load,
      "speech": SampleReview.speech,
    });
    expect(<Object>[
      repository.payload!["grade"]!,
      repository.payload!["load"]!,
      repository.payload!["speech"]!,
    ], everyElement(isA<int>()));
    expect(reloadCount, 1);
  });

  testWidgets("shows a localized snackbar when saving a review fails", (
    WidgetTester tester,
  ) async {
    await _pumpReviewWriteBlock(
      tester,
      repository: _FakeReviewRepository(failure: StateError("save failed")),
    );

    await tester.enterText(find.byType(EditableText), "updated review");
    await tester.pump();
    await tester.tap(find.byKey(const Key("review_write_submit")));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text("error.save_review".tr()), findsOneWidget);
  });
}
