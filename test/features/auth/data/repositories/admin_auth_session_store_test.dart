import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/features/auth/data/repositories/admin_auth_session_store.dart';

import '../../../../fixtures/repository_fixtures.dart';
import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('AdminAuthSessionStore', () {
    late InMemoryStorageService storage;
    late AdminAuthSessionStore store;

    setUp(() {
      storage = InMemoryStorageService();
      store = AdminAuthSessionStore(storage);
    });

    test('saveSession persists tokens, user, menu, and urls', () async {
      final session = RepositoryFixtures.adminAuthSession(
        menu: ['dashboard'],
      );

      await store.saveSession(session);

      expect(storage.get(StorageKeys.loggedInUserToken), 'access_token');
      expect(storage.get(StorageKeys.loggedInUserRefreshToken), 'refresh_token');
      expect(storage.get(StorageKeys.loggedInUserProfileId), session.user.id);
      expect(storage.get(StorageKeys.loggedInUserUuid), session.user.id);
      expect(storage.get(StorageKeys.loggedInUserTenantId), session.user.currentTenant.id);
      expect(storage.get(StorageKeys.authTenantSlug), 'default');
      expect(storage.get(StorageKeys.authMenu), isNotNull);
      expect(storage.get(StorageKeys.authUser), isNotNull);
    });

    test('readSession round-trips saved session', () async {
      final session = RepositoryFixtures.adminAuthSession();
      await store.saveSession(session);

      final restored = store.readSession();

      expect(restored, isNotNull);
      expect(restored!.accessToken, session.accessToken);
      expect(restored.user.email, session.user.email);
      expect(restored.menu, session.menu);
    });

    test('clearSession removes admin session keys', () async {
      await store.saveSession(RepositoryFixtures.adminAuthSession());
      await store.clearSession();

      expect(storage.get(StorageKeys.loggedInUserToken), isNull);
      expect(storage.get(StorageKeys.authUser), isNull);
      expect(storage.get(StorageKeys.authMenu), isNull);
      expect(store.readSession(), isNull);
    });
  });
}
