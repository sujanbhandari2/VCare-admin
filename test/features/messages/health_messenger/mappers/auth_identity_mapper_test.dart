import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/features/messages/health_messenger/mappers/auth_identity_mapper.dart';

import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('AuthIdentityMapper', () {
    late InMemoryStorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
    });

    test('externalUserId prefers loggedInUserUuid', () async {
      await storage.set(StorageKeys.loggedInUserUuid, 'uuid-1');
      await storage.set(StorageKeys.loggedInUserProfileId, 'profile-1');

      final mapper = AuthIdentityMapper(storage: storage);

      expect(mapper.externalUserId, 'uuid-1');
    });

    test('externalUserId falls back to sessionExternalUserId', () async {
      await storage.set(StorageKeys.loggedInUserProfileId, 'profile-1');

      final mapper = AuthIdentityMapper(
        storage: storage,
        sessionExternalUserId: 'session-user-1',
      );

      expect(mapper.externalUserId, 'session-user-1');
    });

    test('externalUserId falls back to loggedInUserProfileId', () async {
      await storage.set(StorageKeys.loggedInUserProfileId, 'profile-1');

      final mapper = AuthIdentityMapper(storage: storage);

      expect(mapper.externalUserId, 'profile-1');
    });

    test('externalUserId falls back to legacy int id', () async {
      await storage.set(StorageKeys.loggedInUserId, 42);

      final mapper = AuthIdentityMapper(storage: storage);

      expect(mapper.externalUserId, '42');
    });

    test('externalTenantId reads loggedInUserTenantId', () async {
      await storage.set(StorageKeys.loggedInUserTenantId, 'tenant-1');

      final mapper = AuthIdentityMapper(storage: storage);

      expect(mapper.externalTenantId, 'tenant-1');
    });

    test('email prefers storage then session', () async {
      final fromSession = AuthIdentityMapper(
        storage: storage,
        sessionEmail: 'session@example.com',
      );
      expect(fromSession.email, 'session@example.com');

      await storage.set(StorageKeys.loggedInUserEmail, 'stored@example.com');
      final fromStorage = AuthIdentityMapper(
        storage: storage,
        sessionEmail: 'session@example.com',
      );
      expect(fromStorage.email, 'stored@example.com');
    });

    test('displayName prefers session when profile and username missing', () {
      final mapper = AuthIdentityMapper(
        storage: storage,
        sessionDisplayName: 'Admin User',
        sessionEmail: 'admin@example.com',
      );

      expect(mapper.displayName, 'Admin User');
    });
  });
}
