import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/onboarding/presentation/providers/is_already_onboarded_provider.dart';

import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('isAlreadyOnboardedProvider', () {
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

    test('defaults to false when key is missing', () {
      expect(container.read(isAlreadyOnboardedProvider), isFalse);
    });

    test('returns true when onboarding flag is saved', () async {
      await storageService.set(StorageKeys.alreadyOnboarded, true);

      expect(container.read(isAlreadyOnboardedProvider), isTrue);
    });
  });
}
