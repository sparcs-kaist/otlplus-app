import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/pages/user_page.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/widgets/review_write_block.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/extensions.dart';
import 'utils/samples.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestWidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('user page exposes stable keys for account actions', (
    tester,
  ) async {
    final storage = StorageService(
      tokenVault: _NoopTokenVault(),
      legacyStorage: _NoopLegacyTokenStorage(),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<InfoModel>.value(value: _UserInfoModel()),
          ChangeNotifierProvider<AuthModel>.value(value: AuthModel(storage)),
        ],
        child: UserPage().scaffold,
      ),
    );

    expect(find.byKey(const Key('user_my_review_button')), findsOneWidget);
    expect(find.byKey(const Key('user_liked_review_button')), findsOneWidget);
    expect(find.byKey(const Key('user_logout_button')), findsOneWidget);
  });

  testWidgets('review write block exposes stable keys for field and submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<ReviewRepository>.value(
        value: _NoopReviewRepository(),
        child: ReviewWriteBlock(
          lecture: SampleLecture.shared,
          existingReview: SampleReview.shared,
        ).scaffold,
      ),
    );

    expect(find.byKey(const Key('review_write_field')), findsOneWidget);
    expect(find.byKey(const Key('review_write_submit')), findsOneWidget);
  });
}

User _sampleUser() {
  return User(
    id: 1,
    email: '',
    studentId: '',
    firstName: '',
    lastName: '',
    majors: [],
    departments: [],
    myTimetableLectures: [],
    reviewWritableLectures: <Lecture>[],
    reviews: [],
  );
}

class _UserInfoModel extends InfoModel {
  @override
  User get user => _sampleUser();

  @override
  User? get userOrNull => _sampleUser();
}

class _NoopReviewRepository extends ReviewRepository {
  _NoopReviewRepository() : super(Dio());
}

class _NoopTokenVault implements TokenVault {
  @override
  Future<void> clear() async {}

  @override
  Future<bool> clearIfRefreshTokenMatches(String expectedRefreshToken) async =>
      false;

  @override
  Future<TokenPair?> read() async => null;

  @override
  Future<void> write(TokenPair pair) async {}

  @override
  Future<bool> writeIfRefreshTokenMatches({
    required String expectedRefreshToken,
    required TokenPair value,
  }) async => false;

  @override
  Future<String?> acquireRefreshLease() async => null;

  @override
  Future<void> releaseRefreshLease(String leaseId) async {}

  @override
  Future<void> syncReplicas() async {}
}

class _NoopLegacyTokenStorage implements LegacyTokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;
}
