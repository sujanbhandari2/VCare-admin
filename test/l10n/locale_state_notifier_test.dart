import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/core/services/storage/storage_keys.dart';
import 'package:flutter_template/core/services/storage/storage_service_provider.dart';
import 'package:flutter_template/l10n/l10n.dart';

import '../helpers/in_memory_storage_service.dart';

void main() {
  group('LocaleStateNotifier', () {
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

    test('defaults to English locale when not stored', () {
      final locale = container.read(localeStateProvider);
      expect(locale.languageCode, L10n.en.languageCode);
    });

    test('reads saved locale code from storage', () async {
      await storageService.set(StorageKeys.locale, L10n.bn.languageCode);

      final locale = container.read(localeStateProvider);
      expect(locale.languageCode, L10n.bn.languageCode);
    });

    test('changeLocale updates state and persists value', () async {
      await container.read(localeStateProvider.notifier).changeLocale(L10n.ne);

      expect(
        container.read(localeStateProvider).languageCode,
        L10n.ne.languageCode,
      );
      expect(storageService.get(StorageKeys.locale), L10n.ne.languageCode);
    });
  });
}
