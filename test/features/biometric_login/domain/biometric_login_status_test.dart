import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/features/auth/data/repositories/auth_secure_token_store.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';

import '../../../helpers/in_memory_storage_service.dart';

void main() {
  group('BiometricLoginStatus account scoping', () {
    test('belongsToAccount requires exact account id match', () {
      const status = BiometricLoginStatus(
        isEnrolled: true,
        accountId: 'user-a',
      );

      expect(status.belongsToAccount('user-a'), isTrue);
      expect(status.belongsToAccount('user-b'), isFalse);
      expect(status.belongsToAccount(null), isFalse);
      expect(status.belongsToAccount(''), isFalse);
    });
  });

  group('AuthSecureTokenStore', () {
    test('save mirrors tokens into StorageService and secure store', () async {
      final storage = InMemoryStorageService();
      final secure = InMemorySecureKvStore();
      final store = AuthSecureTokenStore(
        storage: storage,
        secureStore: secure,
      );

      await store.save(
        accessToken: 'access',
        refreshToken: 'refresh',
      );

      expect(storage.get(StorageKeys.loggedInUserToken), 'access');
      expect(storage.get(StorageKeys.loggedInUserRefreshToken), 'refresh');
      expect(secure.values[AuthSecureTokenStore.accessTokenKey], 'access');
      expect(secure.values[AuthSecureTokenStore.refreshTokenKey], 'refresh');
    });

    test('hydrate migrates Hive tokens into secure store', () async {
      final storage = InMemoryStorageService();
      final secure = InMemorySecureKvStore();
      await storage.set(StorageKeys.loggedInUserToken, 'hive-access');
      await storage.set(StorageKeys.loggedInUserRefreshToken, 'hive-refresh');

      final store = AuthSecureTokenStore(
        storage: storage,
        secureStore: secure,
      );
      await store.hydrate();

      expect(secure.values[AuthSecureTokenStore.accessTokenKey], 'hive-access');
      expect(
        secure.values[AuthSecureTokenStore.refreshTokenKey],
        'hive-refresh',
      );
    });

    test('clear removes mirrored tokens from both stores', () async {
      final storage = InMemoryStorageService();
      final secure = InMemorySecureKvStore();
      final store = AuthSecureTokenStore(
        storage: storage,
        secureStore: secure,
      );
      await store.save(accessToken: 'access', refreshToken: 'refresh');

      await store.clear();

      expect(storage.get(StorageKeys.loggedInUserToken), isNull);
      expect(storage.get(StorageKeys.loggedInUserRefreshToken), isNull);
      expect(secure.values.containsKey(AuthSecureTokenStore.accessTokenKey), isFalse);
    });
  });
}
