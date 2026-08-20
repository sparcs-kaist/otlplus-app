import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/services/storage_service.dart";

class FakeTokenVault implements TokenVault {
  TokenPair? pair;
  int readCount = 0;
  int writeCount = 0;
  int clearCount = 0;

  @override
  Future<TokenPair?> read() async {
    readCount += 1;
    return pair;
  }

  @override
  Future<void> write(TokenPair value) async {
    writeCount += 1;
    pair = value;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    pair = null;
  }

  @override
  Future<bool> writeIfRefreshTokenMatches({
    required String expectedRefreshToken,
    required TokenPair value,
  }) async {
    if (pair?.refreshToken != expectedRefreshToken) return false;
    writeCount += 1;
    pair = value;
    return true;
  }

  @override
  Future<bool> clearIfRefreshTokenMatches(String expectedRefreshToken) async {
    if (pair?.refreshToken != expectedRefreshToken) return false;
    clearCount += 1;
    pair = null;
    return true;
  }

  @override
  Future<String?> acquireRefreshLease() async => "test-lease";

  @override
  Future<void> releaseRefreshLease(String leaseId) async {}

  @override
  Future<void> syncReplicas() async {}
}

class FakeLegacyTokenStorage implements LegacyTokenStorage {
  FakeLegacyTokenStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  int readAccessCount = 0;
  int readRefreshCount = 0;
  int clearCount = 0;

  @override
  Future<String?> readAccessToken() async {
    readAccessCount += 1;
    return accessToken;
  }

  @override
  Future<String?> readRefreshToken() async {
    readRefreshCount += 1;
    return refreshToken;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    accessToken = null;
    refreshToken = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tokenVaultChannel = MethodChannel("org.sparcs.otlplus/token_vault");

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tokenVaultChannel, (_) async => null);
  });

  test("native vault uses the platform channel token-pair contract", () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tokenVaultChannel, (call) async {
          calls.add(call);
          if (call.method == "readTokenPair") {
            return <String, String>{
              "accessToken": "native-access",
              "refreshToken": "native-refresh",
            };
          }
          if (call.method.endsWith("IfRefreshTokenMatches")) return true;
          if (call.method == "acquireRefreshLease") return "native-lease";
          return null;
        });
    const vault = NativeTokenVault();

    final pair = await vault.read();
    await vault.write(
      const TokenPair(accessToken: "new-access", refreshToken: "new-refresh"),
    );
    await vault.clear();
    final conditionallyWritten = await vault.writeIfRefreshTokenMatches(
      expectedRefreshToken: "native-refresh",
      value: const TokenPair(
        accessToken: "conditional-access",
        refreshToken: "conditional-refresh",
      ),
    );
    final conditionallyCleared = await vault.clearIfRefreshTokenMatches(
      "conditional-refresh",
    );
    final leaseId = await vault.acquireRefreshLease();
    await vault.releaseRefreshLease(leaseId!);
    await vault.syncReplicas();

    expect(pair?.accessToken, "native-access");
    expect(pair?.refreshToken, "native-refresh");
    expect(conditionallyWritten, isTrue);
    expect(conditionallyCleared, isTrue);
    expect(calls.map((call) => call.method), <String>[
      "readTokenPair",
      "writeTokenPair",
      "clearTokenPair",
      "writeTokenPairIfRefreshTokenMatches",
      "clearTokenPairIfRefreshTokenMatches",
      "acquireRefreshLease",
      "releaseRefreshLease",
      "syncTokenReplicas",
    ]);
    expect(calls[1].arguments, <String, String>{
      "accessToken": "new-access",
      "refreshToken": "new-refresh",
    });
  });

  test("native vault rejects an invalid platform token pair", () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          tokenVaultChannel,
          (_) async => <String, String>{"accessToken": "access"},
        );

    expect(const NativeTokenVault().read, throwsStateError);
  });

  test(
    "reads an existing native token pair without touching legacy storage",
    () async {
      final vault = FakeTokenVault()
        ..pair = const TokenPair(
          accessToken: "access",
          refreshToken: "refresh",
        );
      final legacy = FakeLegacyTokenStorage(
        accessToken: "legacy-access",
        refreshToken: "legacy-refresh",
      );
      final storage = StorageService(tokenVault: vault, legacyStorage: legacy);

      expect(await storage.getAccessToken(), "access");
      expect(await storage.getRefreshToken(), "refresh");
      expect(legacy.readAccessCount, 0);
      expect(legacy.readRefreshCount, 0);
      expect(vault.writeCount, 0);
    },
  );

  test("migrates a complete legacy pair and removes the legacy copy", () async {
    final vault = FakeTokenVault();
    final legacy = FakeLegacyTokenStorage(
      accessToken: "legacy-access",
      refreshToken: "legacy-refresh",
    );
    final storage = StorageService(tokenVault: vault, legacyStorage: legacy);

    expect(await storage.getAccessToken(), "legacy-access");
    expect(vault.pair?.accessToken, "legacy-access");
    expect(vault.pair?.refreshToken, "legacy-refresh");
    expect(vault.writeCount, 1);
    expect(legacy.clearCount, 1);

    expect(await storage.getRefreshToken(), "legacy-refresh");
    expect(vault.writeCount, 1);
    expect(legacy.clearCount, 1);
  });

  test("does not migrate or delete an incomplete legacy pair", () async {
    final vault = FakeTokenVault();
    final legacy = FakeLegacyTokenStorage(accessToken: "legacy-access");
    final storage = StorageService(tokenVault: vault, legacyStorage: legacy);

    expect(await storage.getAccessToken(), isNull);
    expect(vault.writeCount, 0);
    expect(legacy.clearCount, 0);
  });

  test("saves and clears the token pair through the native vault", () async {
    final vault = FakeTokenVault();
    final legacy = FakeLegacyTokenStorage(
      accessToken: "legacy-access",
      refreshToken: "legacy-refresh",
    );
    final storage = StorageService(tokenVault: vault, legacyStorage: legacy);

    await storage.saveTokens(accessToken: "access", refreshToken: "refresh");

    expect(vault.pair?.accessToken, "access");
    expect(vault.pair?.refreshToken, "refresh");
    expect(vault.writeCount, 1);
    expect(legacy.clearCount, 1);

    await storage.deleteTokens();

    expect(vault.pair, isNull);
    expect(vault.clearCount, 1);
    expect(legacy.clearCount, 2);
  });

  test("rejects empty token values at the storage boundary", () async {
    final storage = StorageService(
      tokenVault: FakeTokenVault(),
      legacyStorage: FakeLegacyTokenStorage(),
    );

    expect(
      () => storage.saveTokens(accessToken: "", refreshToken: "refresh"),
      throwsArgumentError,
    );
    expect(
      () => storage.saveTokens(accessToken: "access", refreshToken: ""),
      throwsArgumentError,
    );
  });

  test("stale refresh results cannot overwrite a newer login", () async {
    final vault = FakeTokenVault()
      ..pair = const TokenPair(
        accessToken: "old-access",
        refreshToken: "old-refresh",
      );
    final storage = StorageService(
      tokenVault: vault,
      legacyStorage: FakeLegacyTokenStorage(),
    );

    await storage.saveTokens(
      accessToken: "login-access",
      refreshToken: "login-refresh",
    );
    final written = await storage.saveRefreshedTokens(
      expectedRefreshToken: "old-refresh",
      accessToken: "stale-access",
      refreshToken: "stale-refresh",
    );

    expect(written, isFalse);
    expect(vault.pair?.accessToken, "login-access");
    expect(vault.pair?.refreshToken, "login-refresh");
  });

  test("stale refresh rejection cannot delete a newer login", () async {
    final vault = FakeTokenVault()
      ..pair = const TokenPair(
        accessToken: "new-access",
        refreshToken: "new-refresh",
      );
    final storage = StorageService(
      tokenVault: vault,
      legacyStorage: FakeLegacyTokenStorage(),
    );

    final cleared = await storage.deleteTokensIfRefreshTokenMatches(
      "old-refresh",
    );

    expect(cleared, isFalse);
    expect(vault.pair?.refreshToken, "new-refresh");
  });

  test("default construction returns one shared storage service", () {
    expect(identical(StorageService(), StorageService()), isTrue);
  });
}
