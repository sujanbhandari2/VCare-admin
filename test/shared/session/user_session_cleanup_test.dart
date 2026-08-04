import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/config/flavor/configuration.dart';
import 'package:vcare_admin/core/config/flavor/configuration_provider.dart';
import 'package:vcare_admin/core/config/flavor/flavor.dart';
import 'package:vcare_admin/core/services/network/http_cache_utils.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/clients_list_state_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/session/user_session_cleanup.dart';

import '../../helpers/in_memory_storage_service.dart';

class _TestConfiguration extends Configuration {
  const _TestConfiguration()
    : super(
        maxCacheAge: const Duration(days: 1),
        dioCacheForceRefreshKey: 'test_force_refresh',
        hiveBoxName: 'test_box',
        baseUrl: 'https://example.com/',
      );

  @override
  String get apiBaseUrl => apiBaseUrlV1;

  @override
  Flavor get flavor => Flavor.dev;
}

void main() {
  group('clearHttpResponseCache', () {
    test('removes only GET-prefixed cache keys', () async {
      final storage = InMemoryStorageService();

      await storage.set('GET:https://example.com/api/v1/auth/me/', {'cached': true});
      await storage.set(StorageKeys.loggedInUserToken, 'token');
      await storage.set(StorageKeys.themeMode, 'dark');

      await clearHttpResponseCache(storage);

      expect(storage.has('GET:https://example.com/api/v1/auth/me/'), isFalse);
      expect(storage.get(StorageKeys.loggedInUserToken), 'token');
      expect(storage.get(StorageKeys.themeMode), 'dark');
    });
  });

  group('clearUserSessionStorage', () {
    test('removes session keys, local profile, and HTTP cache', () async {
      final storage = InMemoryStorageService();
      const config = _TestConfiguration();

      await storage.set(StorageKeys.loggedInUserToken, 'token');
      await storage.set(StorageKeys.loggedInUserRefreshToken, 'refresh');
      await storage.set(StorageKeys.loggedInUserId, 42);
      await storage.set(StorageKeys.loggedInUserProfileId, 'profile-id');
      await storage.set(
        StorageKeys.loggedInUserTenantId,
        '1b4b5118-055f-44e7-9ddd-59e5e357e756',
      );
      await storage.set(StorageKeys.loggedInUserEmail, 'user@example.com');
      await storage.set(StorageKeys.loggedInUserUsername, 'user');
      await storage.set(StorageKeys.tokenRefreshedDate, '2026-01-01T00:00:00.000');
      await storage.set(StorageKeys.lastSyncedFcmToken, 'fcm');
      await storage.set(StorageKeys.lastSyncedFcmUserId, '42');
      await storage.set(StorageKeys.localProfile, {'fullName': 'Old User'});
      await storage.set('GET:https://example.com/api/v1/agents/clients/', {
        'cached': true,
      });

      await clearUserSessionStorage(
        storage: storage,
        apiBaseUrl: config.apiBaseUrl,
      );

      for (final key in [
        StorageKeys.loggedInUserToken,
        StorageKeys.loggedInUserRefreshToken,
        StorageKeys.loggedInUserId,
        StorageKeys.loggedInUserProfileId,
        StorageKeys.loggedInUserTenantId,
        StorageKeys.loggedInUserEmail,
        StorageKeys.loggedInUserUsername,
        StorageKeys.tokenRefreshedDate,
        StorageKeys.lastSyncedFcmToken,
        StorageKeys.lastSyncedFcmUserId,
        StorageKeys.localProfile,
      ]) {
        expect(storage.has(key), isFalse, reason: key);
      }

      expect(storage.has('GET:https://example.com/api/v1/agents/clients/'), isFalse);
    });
  });

  group('clearUserSession', () {
    late InMemoryStorageService storage;
    late ProviderContainer container;

    setUp(() {
      storage = InMemoryStorageService();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          flavorConfigurationProvider.overrideWithValue(const _TestConfiguration()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('clears storage, invalidates providers, and resets network session',
        () async {
      await storage.set(StorageKeys.loggedInUserToken, 'token');
      await storage.set(StorageKeys.loggedInUserId, 10);
      container.read(networkFetchSessionProvider.notifier).markSessionHydrated();

      await clearUserSessionWithoutRef(
        storage: storage,
        apiBaseUrl: const _TestConfiguration().apiBaseUrl,
        container: container,
      );

      expect(storage.has(StorageKeys.loggedInUserToken), isFalse);
      expect(container.read(userLoggedInStateProvider), isFalse);
      expect(container.read(networkFetchSessionProvider), isTrue);
      expect(container.read(clientsListStateProvider).items, isEmpty);
    });
  });
}
