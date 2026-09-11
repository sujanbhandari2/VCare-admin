import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';

/// Thin key/value contract so unit tests can avoid platform plugins.
abstract class SecureKvStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterSecureKvStore implements SecureKvStore {
  FlutterSecureKvStore({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> read(String key) => _secureStorage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _secureStorage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => _secureStorage.delete(key: key);
}

class InMemorySecureKvStore implements SecureKvStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

/// Encrypted durable store for access/refresh tokens.
///
/// Tokens are dual-written to [SecureKvStore] (encrypted at rest on device) and
/// mirrored into [StorageService] so existing sync Dio/header reads keep working.
/// On hydrate, secure storage is preferred and Hive is backfilled or migrated.
class AuthSecureTokenStore {
  AuthSecureTokenStore({
    required StorageService storage,
    SecureKvStore? secureStore,
  })  : _storage = storage,
        _secureStore = secureStore ?? FlutterSecureKvStore();

  static const String accessTokenKey = 'vcare.auth.access_token.v1';
  static const String refreshTokenKey = 'vcare.auth.refresh_token.v1';

  final StorageService _storage;
  final SecureKvStore _secureStore;

  /// Loads tokens from secure storage (or migrates from Hive) into Hive cache.
  Future<void> hydrate() async {
    var access = (await _secureStore.read(accessTokenKey))?.trim() ?? '';
    var refresh = (await _secureStore.read(refreshTokenKey))?.trim() ?? '';

    final hiveAccess =
        _storage.get(StorageKeys.loggedInUserToken)?.toString().trim() ?? '';
    final hiveRefresh =
        _storage.get(StorageKeys.loggedInUserRefreshToken)?.toString().trim() ??
            '';

    if (access.isEmpty && hiveAccess.isNotEmpty) {
      access = hiveAccess;
      refresh = hiveRefresh;
      await _secureStore.write(accessTokenKey, access);
      if (refresh.isNotEmpty) {
        await _secureStore.write(refreshTokenKey, refresh);
      }
    }

    if (access.isNotEmpty) {
      await _storage.set(StorageKeys.loggedInUserToken, access);
    }
    if (refresh.isNotEmpty) {
      await _storage.set(StorageKeys.loggedInUserRefreshToken, refresh);
    }
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    final access = accessToken.trim();
    final refresh = refreshToken.trim();

    await _secureStore.write(accessTokenKey, access);
    await _secureStore.write(refreshTokenKey, refresh);
    await _storage.set(StorageKeys.loggedInUserToken, access);
    await _storage.set(StorageKeys.loggedInUserRefreshToken, refresh);
  }

  Future<void> clear() async {
    await _secureStore.delete(accessTokenKey);
    await _secureStore.delete(refreshTokenKey);
    await _storage.remove(StorageKeys.loggedInUserToken);
    await _storage.remove(StorageKeys.loggedInUserRefreshToken);
  }
}
