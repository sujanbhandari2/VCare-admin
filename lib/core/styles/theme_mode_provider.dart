import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final modeName =
        ref
                .read(storageServiceProvider)
                .get(StorageKeys.themeMode, defaultValue: ThemeMode.system.name)
            as String?;

    return ThemeMode.values.firstWhere(
      (value) => value.name == modeName,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (state == mode) return;

    await ref
        .read(storageServiceProvider)
        .set(StorageKeys.themeMode, mode.name);
    state = mode;
  }
}
