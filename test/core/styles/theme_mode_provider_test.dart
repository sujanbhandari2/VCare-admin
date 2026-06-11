import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/core/styles/theme_mode_provider.dart';

import '../../helpers/in_memory_storage_service.dart';

void main() {
  group('ThemeModeNotifier', () {
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

    test('defaults to system mode when not stored', () {
      final mode = container.read(themeModeProvider);
      expect(mode, ThemeMode.system);
    });

    test('reads saved mode from storage', () async {
      await storageService.set(StorageKeys.themeMode, ThemeMode.dark.name);

      final mode = container.read(themeModeProvider);
      expect(mode, ThemeMode.dark);
    });

    test('updateThemeMode updates state and persists value', () async {
      await container
          .read(themeModeProvider.notifier)
          .updateThemeMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(storageService.get(StorageKeys.themeMode), ThemeMode.light.name);
    });
  });
}
