import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/core/services/storage/storage_keys.dart';
import 'package:flutter_template/core/services/storage/storage_service_provider.dart';
import 'package:flutter_template/core/styles/app_colors.dart';

enum AppColorSchemeStyle {
  tonalSpot(DynamicSchemeVariant.tonalSpot),
  fidelity(DynamicSchemeVariant.fidelity),
  expressive(DynamicSchemeVariant.expressive);

  const AppColorSchemeStyle(this.variant);

  final DynamicSchemeVariant variant;
}

enum AppContrastMode {
  normal(0.0),
  medium(0.5),
  high(1.0);

  const AppContrastMode(this.level);

  final double level;
}

class ThemeAppearanceSettings {
  const ThemeAppearanceSettings({
    required this.seedColor,
    required this.colorSchemeStyle,
    required this.contrastMode,
    required this.seedSourceImagePath,
    required this.useSeedSourceImage,
  });

  final Color seedColor;
  final AppColorSchemeStyle colorSchemeStyle;
  final AppContrastMode contrastMode;
  final String? seedSourceImagePath;
  final bool useSeedSourceImage;

  ThemeAppearanceSettings copyWith({
    Color? seedColor,
    AppColorSchemeStyle? colorSchemeStyle,
    AppContrastMode? contrastMode,
    String? seedSourceImagePath,
    bool? useSeedSourceImage,
    bool updateSeedSourceImagePath = false,
  }) {
    return ThemeAppearanceSettings(
      seedColor: seedColor ?? this.seedColor,
      colorSchemeStyle: colorSchemeStyle ?? this.colorSchemeStyle,
      contrastMode: contrastMode ?? this.contrastMode,
      seedSourceImagePath: updateSeedSourceImagePath
          ? seedSourceImagePath
          : this.seedSourceImagePath,
      useSeedSourceImage: useSeedSourceImage ?? this.useSeedSourceImage,
    );
  }
}

final themeAppearanceProvider =
    NotifierProvider<ThemeAppearanceNotifier, ThemeAppearanceSettings>(
      ThemeAppearanceNotifier.new,
    );

class ThemeAppearanceNotifier extends Notifier<ThemeAppearanceSettings> {
  @override
  ThemeAppearanceSettings build() {
    final storage = ref.read(storageServiceProvider);

    final seedColorValue = storage.get(
      StorageKeys.themeSeedColor,
      defaultValue: AppColors.primaryColor.toARGB32(),
    );

    final styleName = storage.get(
      StorageKeys.colorSchemeStyle,
      defaultValue: AppColorSchemeStyle.fidelity.name,
    );

    final contrastName = storage.get(
      StorageKeys.contrastMode,
      defaultValue: AppContrastMode.normal.name,
    );
    final sourceImagePath = storage.get(StorageKeys.themeSeedSourceImagePath);
    final useImageSource = storage.get(
      StorageKeys.themeSeedUseImageSource,
      defaultValue: false,
    );

    return ThemeAppearanceSettings(
      seedColor: Color(
        (seedColorValue as int?) ?? AppColors.primaryColor.toARGB32(),
      ),
      colorSchemeStyle: AppColorSchemeStyle.values.firstWhere(
        (value) => value.name == styleName,
        orElse: () => AppColorSchemeStyle.fidelity,
      ),
      contrastMode: AppContrastMode.values.firstWhere(
        (value) => value.name == contrastName,
        orElse: () => AppContrastMode.normal,
      ),
      seedSourceImagePath: sourceImagePath as String?,
      useSeedSourceImage: useImageSource as bool? ?? false,
    );
  }

  Future<void> updateSeedColor(Color color) async {
    if (state.seedColor.toARGB32() == color.toARGB32() &&
        !state.useSeedSourceImage) {
      return;
    }

    final storage = ref.read(storageServiceProvider);
    await storage.set(StorageKeys.themeSeedColor, color.toARGB32());
    await storage.set(StorageKeys.themeSeedUseImageSource, false);
    state = state.copyWith(seedColor: color, useSeedSourceImage: false);
  }

  Future<void> updateSeedColorFromImage({
    required Color color,
    required String imagePath,
  }) async {
    if (state.seedColor.toARGB32() == color.toARGB32() &&
        state.seedSourceImagePath == imagePath) {
      return;
    }

    final storage = ref.read(storageServiceProvider);
    await storage.set(StorageKeys.themeSeedColor, color.toARGB32());
    await storage.set(StorageKeys.themeSeedSourceImagePath, imagePath);
    await storage.set(StorageKeys.themeSeedUseImageSource, true);
    state = state.copyWith(
      seedColor: color,
      seedSourceImagePath: imagePath,
      useSeedSourceImage: true,
      updateSeedSourceImagePath: true,
    );
  }

  Future<void> updateColorSchemeStyle(AppColorSchemeStyle style) async {
    if (state.colorSchemeStyle == style) return;

    await ref
        .read(storageServiceProvider)
        .set(StorageKeys.colorSchemeStyle, style.name);
    state = state.copyWith(colorSchemeStyle: style);
  }

  Future<void> updateContrastMode(AppContrastMode mode) async {
    if (state.contrastMode == mode) return;

    await ref
        .read(storageServiceProvider)
        .set(StorageKeys.contrastMode, mode.name);
    state = state.copyWith(contrastMode: mode);
  }
}
