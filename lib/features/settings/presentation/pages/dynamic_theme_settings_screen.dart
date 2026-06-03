import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_template/core/styles/text_scale_provider.dart';
import 'package:flutter_template/core/styles/theme_appearance_provider.dart';
import 'package:flutter_template/core/styles/theme_mode_provider.dart';
import 'package:flutter_template/shared/utils/image_color_extractor.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';
import 'package:flutter_template/shared/utils/image_picker_utils.dart';
import 'package:flutter_template/shared/widgets/image_picker_source_selection_bottom_sheet.dart';

class DynamicThemeSettingsScreen extends ConsumerWidget {
  const DynamicThemeSettingsScreen({super.key});

  static const List<(ThemeMode, IconData)> _themeModes = [
    (ThemeMode.system, Icons.settings_suggest_outlined),
    (ThemeMode.light, Icons.light_mode_outlined),
    (ThemeMode.dark, Icons.dark_mode_outlined),
  ];

  static const List<(AppTextScale, IconData)> _textScales = [
    (AppTextScale.small, Icons.text_decrease_outlined),
    (AppTextScale.normal, Icons.text_fields_outlined),
    (AppTextScale.large, Icons.text_increase_outlined),
  ];

  static const List<(AppColorSchemeStyle, IconData)> _colorSchemeStyles = [
    (AppColorSchemeStyle.tonalSpot, Icons.gradient_outlined),
    (AppColorSchemeStyle.fidelity, Icons.tune_outlined),
    (AppColorSchemeStyle.expressive, Icons.auto_awesome_outlined),
  ];

  static const List<(AppContrastMode, IconData)> _contrastModes = [
    (AppContrastMode.normal, Icons.brightness_medium_outlined),
    (AppContrastMode.medium, Icons.brightness_6_outlined),
    (AppContrastMode.high, Icons.brightness_high_outlined),
  ];

  static const List<Color> _seedColors = [
    Color(0xff912478),
    Color(0xff005ac1),
    Color(0xff0f766e),
    Color(0xff2d5f2e),
    Color(0xffbf360c),
    Color(0xff4a148c),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedThemeMode = ref.watch(themeModeProvider);
    final selectedTextScale = ref.watch(textScaleProvider);
    final themeAppearance = ref.watch(themeAppearanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.appLocalization.settings_theme_and_color_scheme),
        leading: const BackButton(
          style: ButtonStyle(iconSize: WidgetStatePropertyAll(20)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
        children: [
          _SettingsSectionCard(
            title: context.appLocalization.theme_mode,
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _themeModes.map((item) {
                final mode = item.$1;
                final icon = item.$2;
                return _SelectionChip(
                  icon: icon,
                  label: _themeModeLabel(context, mode: mode),
                  selected: selectedThemeMode == mode,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).updateThemeMode(mode);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12.0),
          _SettingsSectionCard(
            title: context.appLocalization.text_scale,
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _textScales.map((item) {
                final scale = item.$1;
                final icon = item.$2;
                return _SelectionChip(
                  icon: icon,
                  label: _textScaleLabel(context, scale: scale),
                  selected: selectedTextScale == scale,
                  onTap: () {
                    ref.read(textScaleProvider.notifier).updateTextScale(scale);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12.0),
          _SettingsSectionCard(
            title: context.appLocalization.color_scheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: _colorSchemeStyles.map((item) {
                    final style = item.$1;
                    final icon = item.$2;
                    return _SelectionChip(
                      icon: icon,
                      label: _colorSchemeStyleLabel(context, style: style),
                      selected: themeAppearance.colorSchemeStyle == style,
                      onTap: () {
                        ref
                            .read(themeAppearanceProvider.notifier)
                            .updateColorSchemeStyle(style);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12.0),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    if (themeAppearance.seedSourceImagePath != null)
                      _ImageSwatchChip(
                        imagePath: themeAppearance.seedSourceImagePath!,
                        selected: themeAppearance.useSeedSourceImage,
                        onTap: () async {
                          await _applySavedImageColor(
                            context,
                            ref,
                            themeAppearance.seedSourceImagePath!,
                          );
                        },
                      ),
                    ..._seedColors.map((color) {
                      return _ColorSwatchChip(
                        color: color,
                        selected:
                            themeAppearance.seedColor.toARGB32() ==
                                color.toARGB32() &&
                            !themeAppearance.useSeedSourceImage,
                        onTap: () {
                          ref
                              .read(themeAppearanceProvider.notifier)
                              .updateSeedColor(color);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12.0),
                OutlinedButton.icon(
                  onPressed: () {
                    _onGenerateFromImageTap(context, ref);
                  },
                  icon: const Icon(Icons.image_search_outlined, size: 18.0),
                  label: Text(
                    context.appLocalization.color_scheme_generate_from_image,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          _SettingsSectionCard(
            title: context.appLocalization.contrast_mode,
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _contrastModes.map((item) {
                final mode = item.$1;
                final icon = item.$2;
                return _SelectionChip(
                  icon: icon,
                  label: _contrastModeLabel(context, mode: mode),
                  selected: themeAppearance.contrastMode == mode,
                  onTap: () {
                    ref
                        .read(themeAppearanceProvider.notifier)
                        .updateContrastMode(mode);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGenerateFromImageTap(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ImagePickerSourceSelectionBottomSheet.show<void>(
      context,
      onGalleryPick: () async {
        await _pickAndApplyColor(context, ref, ImageSource.gallery);
      },
      onCameraPick: () async {
        await _pickAndApplyColor(context, ref, ImageSource.camera);
      },
    );
  }

  Future<void> _pickAndApplyColor(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final image = source == ImageSource.gallery
        ? await ImagePickerUtils.fromGallery()
        : await ImagePickerUtils.fromCamera();

    if (image == null || !context.mounted) return;

    final color = await ImageColorExtractor.extractDominantColor(image);
    if (!context.mounted) return;

    if (color == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.appLocalization.color_scheme_from_image_failed),
        ),
      );
      return;
    }

    await ref
        .read(themeAppearanceProvider.notifier)
        .updateSeedColorFromImage(color: color, imagePath: image.path);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.appLocalization.color_scheme_from_image_applied),
      ),
    );
  }

  Future<void> _applySavedImageColor(
    BuildContext context,
    WidgetRef ref,
    String imagePath,
  ) async {
    final color = await ImageColorExtractor.extractDominantColor(
      XFile(imagePath),
    );
    if (!context.mounted) return;

    if (color == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.appLocalization.color_scheme_from_image_failed),
        ),
      );
      return;
    }

    await ref
        .read(themeAppearanceProvider.notifier)
        .updateSeedColorFromImage(color: color, imagePath: imagePath);
  }

  String _themeModeLabel(BuildContext context, {required ThemeMode mode}) {
    return switch (mode) {
      ThemeMode.system => context.appLocalization.theme_mode_system_default,
      ThemeMode.light => context.appLocalization.theme_mode_light,
      ThemeMode.dark => context.appLocalization.theme_mode_dark,
    };
  }

  String _textScaleLabel(BuildContext context, {required AppTextScale scale}) {
    return switch (scale) {
      AppTextScale.small => context.appLocalization.text_scale_small,
      AppTextScale.normal => context.appLocalization.text_scale_default,
      AppTextScale.large => context.appLocalization.text_scale_large,
    };
  }

  String _colorSchemeStyleLabel(
    BuildContext context, {
    required AppColorSchemeStyle style,
  }) {
    return switch (style) {
      AppColorSchemeStyle.tonalSpot =>
        context.appLocalization.color_scheme_style_tonal_spot,
      AppColorSchemeStyle.fidelity =>
        context.appLocalization.color_scheme_style_fidelity,
      AppColorSchemeStyle.expressive =>
        context.appLocalization.color_scheme_style_expressive,
    };
  }

  String _contrastModeLabel(
    BuildContext context, {
    required AppContrastMode mode,
  }) {
    return switch (mode) {
      AppContrastMode.normal => context.appLocalization.contrast_mode_normal,
      AppContrastMode.medium => context.appLocalization.contrast_mode_medium,
      AppContrastMode.high => context.appLocalization.contrast_mode_high,
    };
  }
}

class _ImageSwatchChip extends StatelessWidget {
  const _ImageSwatchChip({
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final exists = file.existsSync();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38.0,
          width: 38.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: context.theme.colorScheme.onSurface,
                    width: 2.5,
                  )
                : null,
          ),
          child: Padding(
            padding: selected ? const EdgeInsets.all(2.0) : EdgeInsets.zero,
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  exists
                      ? Image.file(file, fit: BoxFit.cover)
                      : Container(
                          color: context.theme.colorScheme.surfaceContainer,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 18.0,
                          ),
                        ),
                  if (selected)
                    const Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_rounded,
                        size: 18.0,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.textTheme.titleSmall),
            const SizedBox(height: 10.0),
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18.0,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchChip extends StatelessWidget {
  const _ColorSwatchChip({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38.0,
          width: 38.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected
                  ? context.theme.colorScheme.onSurface
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, size: 18.0, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
