import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/main.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTokenVault implements TokenVault {
  Completer<void>? writeGate;
  Object? writeError;
  TokenPair? writtenPair;
  int writeCount = 0;

  @override
  Future<TokenPair?> read() async => null;

  @override
  Future<void> write(TokenPair value) async {
    writeCount += 1;
    writtenPair = value;
    await writeGate?.future;
    if (writeError case final error?) throw error;
  }

  @override
  Future<void> clear() async {}

  @override
  Future<bool> writeIfRefreshTokenMatches({
    required String expectedRefreshToken,
    required TokenPair value,
  }) async => false;

  @override
  Future<bool> clearIfRefreshTokenMatches(String expectedRefreshToken) async =>
      false;

  @override
  Future<String?> acquireRefreshLease() async => 'test-lease';

  @override
  Future<void> releaseRefreshLease(String leaseId) async {}

  @override
  Future<void> syncReplicas() async {}
}

class _FakeLegacyTokenStorage implements LegacyTokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> clear() async {}
}

class _RecordingAuthModel extends AuthModel {
  _RecordingAuthModel(StorageService storageService) : super(storageService);

  final loggedInValues = <bool>[];

  @override
  void setLoggedIn(bool loggedIn) {
    loggedInValues.add(loggedIn);
    super.setLoggedIn(loggedIn);
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestWidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'deep link tokens set auth logged in and clear loading when mounted',
    (tester) async {
      final links = StreamController<Uri>();
      final vault = _FakeTokenVault();
      final storage = StorageService(
        tokenVault: vault,
        legacyStorage: _FakeLegacyTokenStorage(),
      );
      final auth = _RecordingAuthModel(storage);
      addTearDown(links.close);

      await tester.pumpWidget(
        _deepLinkHarness(links: links, storage: storage, auth: auth),
      );

      links.add(_loginUri);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(vault.writtenPair?.accessToken, 'access');
      expect(vault.writtenPair?.refreshToken, 'refresh');
      expect(auth.loggedInValues, <bool>[true]);
      expect(find.byKey(const Key('loaded-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('deep link completing after app state disposal does not throw', (
    tester,
  ) async {
    final links = StreamController<Uri>();
    final writeGate = Completer<void>();
    final vault = _FakeTokenVault()..writeGate = writeGate;
    final storage = StorageService(
      tokenVault: vault,
      legacyStorage: _FakeLegacyTokenStorage(),
    );
    final auth = _RecordingAuthModel(storage);
    addTearDown(links.close);

    await tester.pumpWidget(
      _deepLinkHarness(links: links, storage: storage, auth: auth),
    );
    links.add(_loginUri);
    await tester.pump();
    expect(vault.writeCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    writeGate.complete();
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(auth.loggedInValues, <bool>[true]);
  });

  testWidgets(
    'uri stream errors and failing token handling do not escape the guarded zone',
    (tester) async {
      final links = StreamController<Uri>();
      final vault = _FakeTokenVault()
        ..writeError = StateError('token save failed');
      final storage = StorageService(
        tokenVault: vault,
        legacyStorage: _FakeLegacyTokenStorage(),
      );
      final auth = _RecordingAuthModel(storage);
      final escapedErrors = <Object>[];
      final recordedNonFatals = <Object>[];
      addTearDown(links.close);

      await runZonedGuarded<Future<void>>(
        () async {
          await tester.pumpWidget(
            _deepLinkHarness(
              links: links,
              storage: storage,
              auth: auth,
              recordNonFatal: (error, stack) async {
                recordedNonFatals.add(error);
              },
            ),
          );

          links.addError(StateError('uri stream failed'));
          await tester.pump();
          links.add(_loginUri);
          await tester.pump();
          await tester.pump();
          await tester.pump();
        },
        (error, stack) {
          escapedErrors.add(error);
        },
      );

      expect(escapedErrors, isEmpty);
      expect(recordedNonFatals, hasLength(2));
    },
  );
}

Widget _deepLinkHarness({
  required StreamController<Uri> links,
  required StorageService storage,
  required AuthModel auth,
  Future<void> Function(Object error, StackTrace stack)? recordNonFatal,
}) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: ChangeNotifierProvider<AuthModel>.value(
      value: auth,
      child: OTLApp(
        uriLinkStreamOverride: links.stream,
        storageServiceOverride: storage,
        initializeAppOverride: () async {},
        recordNonFatalOverride: recordNonFatal,
        homeOverride: const SizedBox(key: Key('loaded-home')),
      ),
    ),
  );
}

final _loginUri = Uri.parse(
  'org.sparcs.otl://login/?accessToken=access&refreshToken=refresh',
);
