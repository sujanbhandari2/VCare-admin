import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';

import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('userLoggedInStateProvider', () {
    late InMemoryStorageService storageService;
    late ProviderContainer container;

    setUp(() {
      storageService = InMemoryStorageService();
      container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('returns false when token and userId are missing', () {
      expect(container.read(userLoggedInStateProvider), isFalse);
    });

    test('returns false when token is blank', () async {
      await storageService.set(StorageKeys.loggedInUserToken, '   ');
      await storageService.set(StorageKeys.loggedInUserId, 1);

      expect(container.read(userLoggedInStateProvider), isFalse);
    });

    test('returns false when userId is not a positive int', () async {
      await storageService.set(StorageKeys.loggedInUserToken, 'token');
      await storageService.set(StorageKeys.loggedInUserId, 0);

      expect(container.read(userLoggedInStateProvider), isFalse);
    });

    test('returns true when token is non-empty and userId > 0', () async {
      await storageService.set(StorageKeys.loggedInUserToken, 'token');
      await storageService.set(StorageKeys.loggedInUserId, 10);

      expect(container.read(userLoggedInStateProvider), isTrue);
    });
  });
}
