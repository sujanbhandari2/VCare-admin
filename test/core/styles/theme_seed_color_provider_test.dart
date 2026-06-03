import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/core/services/storage/storage_keys.dart';
import 'package:flutter_template/core/services/storage/storage_service_provider.dart';
import 'package:flutter_template/core/styles/app_colors.dart';
import 'package:flutter_template/core/styles/theme_appearance_provider.dart';

import '../../helpers/in_memory_storage_service.dart';

void main() {
  group('ThemeAppearanceNotifier seed color', () {
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

    test('defaults to app primary color when not stored', () {
      final color = container.read(themeAppearanceProvider).seedColor;
      expect(color.toARGB32(), AppColors.primaryColor.toARGB32());
    });

    test('reads saved color from storage', () async {
      const savedColor = Color(0xff005ac1);
      await storageService.set(
        StorageKeys.themeSeedColor,
        savedColor.toARGB32(),
      );

      final color = container.read(themeAppearanceProvider).seedColor;
      expect(color.toARGB32(), savedColor.toARGB32());
    });

    test('updateSeedColor updates state and persists value', () async {
      const newColor = Color(0xff2d5f2e);

      await container
          .read(themeAppearanceProvider.notifier)
          .updateSeedColor(newColor);

      expect(
        container.read(themeAppearanceProvider).seedColor.toARGB32(),
        newColor.toARGB32(),
      );
      expect(
        storageService.get(StorageKeys.themeSeedColor),
        newColor.toARGB32(),
      );
    });
  });
}
