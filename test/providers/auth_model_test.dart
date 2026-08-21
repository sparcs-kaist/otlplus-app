import "package:flutter_test/flutter_test.dart";
import "package:otlplus/providers/auth_model.dart";
import "package:otlplus/services/storage_service.dart";

class AuthTestTokenVault implements TokenVault {
  AuthTestTokenVault({this.failClear = false});

  final bool failClear;
  TokenPair? pair = const TokenPair(
    accessToken: "access",
    refreshToken: "refresh",
  );

  @override
  Future<TokenPair?> read() async => pair;

  @override
  Future<void> write(TokenPair value) async {
    pair = value;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError("clear failed");
    pair = null;
  }

  @override
  Future<bool> writeIfRefreshTokenMatches({
    required String expectedRefreshToken,
    required TokenPair value,
  }) async {
    if (pair?.refreshToken != expectedRefreshToken) return false;
    pair = value;
    return true;
  }

  @override
  Future<bool> clearIfRefreshTokenMatches(String expectedRefreshToken) async {
    if (pair?.refreshToken != expectedRefreshToken) return false;
    await clear();
    return true;
  }

  @override
  Future<String?> acquireRefreshLease() async => "test-lease";

  @override
  Future<void> releaseRefreshLease(String leaseId) async {}

  @override
  Future<void> syncReplicas() async {}
}

class AuthTestLegacyStorage implements LegacyTokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> clear() async {}
}

void main() {
  test(
    "logout changes state only after secure token deletion succeeds",
    () async {
      final vault = AuthTestTokenVault();
      final model = AuthModel(
        StorageService(
          tokenVault: vault,
          legacyStorage: AuthTestLegacyStorage(),
        ),
      )..setLoggedIn(true);

      await model.logout();

      expect(model.isLogined, isFalse);
      expect(vault.pair, isNull);
    },
  );

  test("logout keeps the session visible when secure deletion fails", () async {
    final model = AuthModel(
      StorageService(
        tokenVault: AuthTestTokenVault(failClear: true),
        legacyStorage: AuthTestLegacyStorage(),
      ),
    )..setLoggedIn(true);

    await expectLater(model.logout(), throwsStateError);

    expect(model.isLogined, isTrue);
  });
}
