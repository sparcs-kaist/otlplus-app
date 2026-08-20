import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  Map<String, String> toPlatformMap() => <String, String>{
    "accessToken": accessToken,
    "refreshToken": refreshToken,
  };

  static TokenPair? fromPlatformMap(Map<Object?, Object?>? value) {
    if (value == null) return null;

    final accessToken = value["accessToken"];
    final refreshToken = value["refreshToken"];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw StateError("Native token vault returned an invalid token pair.");
    }
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }
}

abstract interface class TokenVault {
  Future<TokenPair?> read();
  Future<void> write(TokenPair value);
  Future<void> clear();
  Future<bool> writeIfRefreshTokenMatches({
    required String expectedRefreshToken,
    required TokenPair value,
  });
  Future<bool> clearIfRefreshTokenMatches(String expectedRefreshToken);
  Future<String?> acquireRefreshLease();
  Future<void> releaseRefreshLease(String leaseId);
  Future<void> syncReplicas();
}

class NativeTokenVault implements TokenVault {
  static const MethodChannel _channel = MethodChannel(
    "org.sparcs.otlplus/token_vault",
  );

  const NativeTokenVault();

  @override
  Future<TokenPair?> read() async {
    final value = await _channel.invokeMapMethod<Object?, Object?>(
      "readTokenPair",
    );
    return TokenPair.fromPlatformMap(value);
  }

  @override
  Future<void> write(TokenPair value) {
    return _channel.invokeMethod<void>("writeTokenPair", value.toPlatformMap());
  }

  @override
  Future<void> clear() {
    return _channel.invokeMethod<void>("clearTokenPair");
  }

  @override
  Future<bool> writeIfRefreshTokenMatches({
    required String expectedRefreshToken,
    required TokenPair value,
  }) async {
    return await _channel.invokeMethod<bool>(
          "writeTokenPairIfRefreshTokenMatches",
          <String, String>{
            "expectedRefreshToken": expectedRefreshToken,
            ...value.toPlatformMap(),
          },
        ) ??
        false;
  }

  @override
  Future<bool> clearIfRefreshTokenMatches(String expectedRefreshToken) async {
    return await _channel.invokeMethod<bool>(
          "clearTokenPairIfRefreshTokenMatches",
          <String, String>{"expectedRefreshToken": expectedRefreshToken},
        ) ??
        false;
  }

  @override
  Future<String?> acquireRefreshLease() {
    return _channel.invokeMethod<String>("acquireRefreshLease");
  }

  @override
  Future<void> releaseRefreshLease(String leaseId) {
    return _channel.invokeMethod<void>("releaseRefreshLease", <String, String>{
      "leaseId": leaseId,
    });
  }

  @override
  Future<void> syncReplicas() {
    return _channel.invokeMethod<void>("syncTokenReplicas");
  }
}

abstract interface class LegacyTokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> clear();
}

class FlutterSecureStorageLegacyTokenStorage implements LegacyTokenStorage {
  const FlutterSecureStorageLegacyTokenStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const String _accessTokenKey = "accessToken";
  static const String _refreshTokenKey = "refreshToken";

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

class StorageService {
  factory StorageService({
    TokenVault? tokenVault,
    LegacyTokenStorage? legacyStorage,
  }) {
    if (tokenVault == null && legacyStorage == null) return _instance;
    return StorageService._(
      tokenVault: tokenVault ?? const NativeTokenVault(),
      legacyStorage:
          legacyStorage ?? const FlutterSecureStorageLegacyTokenStorage(),
    );
  }

  StorageService._({
    required TokenVault tokenVault,
    required LegacyTokenStorage legacyStorage,
  }) : _tokenVault = tokenVault,
       _legacyStorage = legacyStorage;

  static final StorageService _instance = StorageService._(
    tokenVault: const NativeTokenVault(),
    legacyStorage: const FlutterSecureStorageLegacyTokenStorage(),
  );

  final TokenVault _tokenVault;
  final LegacyTokenStorage _legacyStorage;

  Future<void> _operationTail = Future<void>.value();
  bool _legacyCleanupComplete = false;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _validatePair(accessToken, refreshToken);
    return _exclusive(() async {
      await _tokenVault.write(
        TokenPair(accessToken: accessToken, refreshToken: refreshToken),
      );
      await _legacyStorage.clear();
      _legacyCleanupComplete = true;
    });
  }

  Future<bool> saveRefreshedTokens({
    required String expectedRefreshToken,
    required String accessToken,
    required String refreshToken,
  }) {
    _validatePair(accessToken, refreshToken);
    if (expectedRefreshToken.isEmpty) {
      throw ArgumentError("Expected refresh token must be non-empty.");
    }
    return _exclusive(() async {
      final written = await _tokenVault.writeIfRefreshTokenMatches(
        expectedRefreshToken: expectedRefreshToken,
        value: TokenPair(accessToken: accessToken, refreshToken: refreshToken),
      );
      if (written) {
        await _legacyStorage.clear();
        _legacyCleanupComplete = true;
      }
      return written;
    });
  }

  Future<bool> deleteTokensIfRefreshTokenMatches(String expectedRefreshToken) {
    if (expectedRefreshToken.isEmpty) {
      throw ArgumentError("Expected refresh token must be non-empty.");
    }
    return _exclusive(() async {
      await _legacyStorage.clear();
      _legacyCleanupComplete = true;
      return _tokenVault.clearIfRefreshTokenMatches(expectedRefreshToken);
    });
  }

  Future<TokenPair?> getTokenPair() {
    return _exclusive(_readOrMigrate);
  }

  Future<String?> getAccessToken() async {
    return (await getTokenPair())?.accessToken;
  }

  Future<String?> getRefreshToken() async {
    return (await getTokenPair())?.refreshToken;
  }

  Future<void> deleteTokens() {
    return _exclusive(() async {
      await _legacyStorage.clear();
      await _tokenVault.clear();
      _legacyCleanupComplete = true;
    });
  }

  Future<bool> hasTokens() async {
    return await getTokenPair() != null;
  }

  Future<String?> acquireRefreshLease() {
    return _tokenVault.acquireRefreshLease();
  }

  Future<void> releaseRefreshLease(String leaseId) {
    return _tokenVault.releaseRefreshLease(leaseId);
  }

  Future<void> syncNativeReplicas() {
    return _exclusive(_tokenVault.syncReplicas);
  }

  Future<TokenPair?> _readOrMigrate() async {
    final current = await _tokenVault.read();
    if (current != null) {
      if (!_legacyCleanupComplete) {
        try {
          await _legacyStorage.clear();
          _legacyCleanupComplete = true;
        } catch (_) {
          // The native vault is authoritative. Retry legacy cleanup on the
          // next read without blocking a valid session.
        }
      }
      return current;
    }

    final accessToken = await _legacyStorage.readAccessToken();
    final refreshToken = await _legacyStorage.readRefreshToken();
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    final pair = TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _tokenVault.write(pair);
    await _legacyStorage.clear();
    _legacyCleanupComplete = true;
    return pair;
  }

  Future<T> _exclusive<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationTail = _operationTail.catchError((_) {}).then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  static void _validatePair(String accessToken, String refreshToken) {
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw ArgumentError("Access and refresh tokens must both be non-empty.");
    }
  }
}
