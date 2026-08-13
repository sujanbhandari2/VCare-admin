import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/env/env.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_bootstrap_config.dart';

import '../../../helpers/in_memory_storage_service.dart';

void main() {
  group('HealthMessengerBootstrapConfig', () {
    late InMemoryStorageService storage;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Env.instance.load();
    });

    setUp(() {
      storage = InMemoryStorageService();
    });

    test('resolveExternalUserRole uppercases and defaults empty to AGENT', () {
      expect(
        HealthMessengerBootstrapConfig.resolveExternalUserRole('admin'),
        'ADMIN',
      );
      expect(
        HealthMessengerBootstrapConfig.resolveExternalUserRole('  agent '),
        'AGENT',
      );
      expect(
        HealthMessengerBootstrapConfig.resolveExternalUserRole(null),
        'AGENT',
      );
      expect(
        HealthMessengerBootstrapConfig.resolveExternalUserRole(''),
        'AGENT',
      );
    });

    test('prefixedExternalTenantId keeps known prefixes', () {
      expect(
        HealthMessengerBootstrapConfig.prefixedExternalTenantId('DEV_abc'),
        'DEV_abc',
      );
      expect(
        HealthMessengerBootstrapConfig.prefixedExternalTenantId('QA_abc'),
        'QA_abc',
      );
    });

    test('prefixedExternalTenantId applies flavor prefix when present', () {
      final prefix = HealthMessengerBootstrapConfig.flavorExternalTenantIdPrefix();
      final result =
          HealthMessengerBootstrapConfig.prefixedExternalTenantId('tenant-1');

      if (prefix.isEmpty) {
        expect(result, 'tenant-1');
      } else {
        expect(result, '${prefix}tenant-1');
      }
    });

    test('tryBuild prefers explicit currentTenantId over storage', () async {
      await storage.set(StorageKeys.loggedInUserTenantId, 'storage-tenant');
      await storage.set(StorageKeys.loggedInUserUuid, 'user-1');
      await storage.set(StorageKeys.loggedInUserEmail, 'admin@example.com');

      final config = HealthMessengerBootstrapConfig.tryBuild(
        storage: storage,
        currentTenantId: 'session-tenant',
        externalUserRole: 'ADMIN',
      );

      expect(config, isNotNull);
      expect(
        config!.externalTenantId,
        HealthMessengerBootstrapConfig.prefixedExternalTenantId(
          'session-tenant',
        ),
      );
      expect(config.externalUserId, 'user-1');
      expect(config.externalUserRole, 'ADMIN');
      expect(config.email, 'admin@example.com');
    });

    test('tryBuild uses session identity overrides when storage empty', () {
      final config = HealthMessengerBootstrapConfig.tryBuild(
        storage: storage,
        currentTenantId: 'tenant-from-session',
        sessionExternalUserId: 'session-user',
        sessionEmail: 'session@example.com',
        sessionDisplayName: 'Session User',
        externalUserRole: 'ADMIN',
      );

      expect(config, isNotNull);
      expect(config!.externalUserId, 'session-user');
      expect(config.email, 'session@example.com');
      expect(config.displayName, 'Session User');
      expect(config.externalUserRole, 'ADMIN');
      expect(
        config.externalTenantId,
        HealthMessengerBootstrapConfig.prefixedExternalTenantId(
          'tenant-from-session',
        ),
      );
    });

    test('tryBuild falls back to profile id when uuid missing', () async {
      await storage.set(StorageKeys.loggedInUserProfileId, 'profile-id');
      await storage.set(StorageKeys.loggedInUserEmail, 'admin@example.com');
      await storage.set(StorageKeys.loggedInUserTenantId, 'tenant-1');

      final config = HealthMessengerBootstrapConfig.tryBuild(
        storage: storage,
      );

      expect(config, isNotNull);
      expect(config!.externalUserId, 'profile-id');
    });

    test('tryBuild returns null when tenant missing', () async {
      await storage.set(StorageKeys.loggedInUserUuid, 'user-1');
      await storage.set(StorageKeys.loggedInUserEmail, 'admin@example.com');

      final config = HealthMessengerBootstrapConfig.tryBuild(storage: storage);

      expect(config, isNull);
    });
  });
}
