import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vcare_admin/core/styles/text_scale_provider.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/vcare_assets.dart';
import 'package:vcare_admin/features/tenant_branding/domain/entities/tenant_branding.dart';
import 'package:vcare_admin/features/tenant_branding/domain/tenant_branding_validators.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/widgets/tenant_branded_image.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/image_picker_utils.dart';
import 'package:vcare_admin/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class DynamicThemeSettingsScreen extends ConsumerStatefulWidget {
  const DynamicThemeSettingsScreen({super.key});

  @override
  ConsumerState<DynamicThemeSettingsScreen> createState() =>
      _DynamicThemeSettingsScreenState();
}

class _DynamicThemeSettingsScreenState
    extends ConsumerState<DynamicThemeSettingsScreen> {
  late final TextEditingController _primaryController;
  late final TextEditingController _secondaryController;
  late final TextEditingController _accentController;
  bool _initialized = false;

  static const List<(AppTextScale, IconData)> _textScales = [
    (AppTextScale.small, Icons.text_decrease_outlined),
    (AppTextScale.normal, Icons.text_fields_outlined),
    (AppTextScale.large, Icons.text_increase_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _primaryController = TextEditingController();
    _secondaryController = TextEditingController();
    _accentController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tenantBrandingStateProvider.notifier).refreshFromApi();
    });
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _accentController.dispose();
    super.dispose();
  }

  void _syncControllers(TenantBranding branding) {
    _primaryController.text = branding.primaryColor;
    _secondaryController.text = branding.secondaryColor;
    _accentController.text = branding.accentColor;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final brandingState = ref.watch(tenantBrandingStateProvider);
    final branding = brandingState.branding;
    final selectedTextScale = ref.watch(textScaleProvider);
    final matchedPreset = TenantColorTheme.match(
      primary: branding.primaryColor,
      secondary: branding.secondaryColor,
      accent: branding.accentColor,
    );

    if (!_initialized ||
        (_primaryController.text != branding.primaryColor &&
            !brandingState.updating)) {
      _syncControllers(branding);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.appLocalization.settings_theme_and_color_scheme),
        leading: const BackButton(
          style: ButtonStyle(iconSize: WidgetStatePropertyAll(20)),
        ),
        actions: [
          if (brandingState.isBusy)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SettingsSectionCard(
            title: context.appLocalization.branding_preview,
            child: _BrandingPreview(branding: branding),
          ),
          const SizedBox(height: 12),
          _SettingsSectionCard(
            title: context.appLocalization.branding_colors_section,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...TenantColorTheme.all.map((theme) {
                      final selected = matchedPreset?.key == theme.key;
                      return _ColorPresetChip(
                        theme: theme,
                        selected: selected,
                        onTap: brandingState.isBusy
                            ? null
                            : () => _applyPreset(theme),
                      );
                    }),
                    _SelectionChip(
                      icon: Icons.palette_outlined,
                      label: context.appLocalization.branding_custom_colors,
                      selected: matchedPreset == null,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _HexColorField(
                  label: context.appLocalization.branding_primary_color,
                  controller: _primaryController,
                  enabled: !brandingState.isBusy,
                ),
                const SizedBox(height: 12),
                _HexColorField(
                  label: context.appLocalization.branding_secondary_color,
                  controller: _secondaryController,
                  enabled: !brandingState.isBusy,
                ),
                const SizedBox(height: 12),
                _HexColorField(
                  label: context.appLocalization.branding_accent_color,
                  controller: _accentController,
                  enabled: !brandingState.isBusy,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: brandingState.isBusy ? null : _saveColors,
                        child: Text(context.appLocalization.branding_save),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: brandingState.isBusy ? null : _reset,
                        child: Text(context.appLocalization.branding_reset),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsSectionCard(
            title: context.appLocalization.branding_fonts_section,
            child: Column(
              children: VCareFontTheme.all.map((font) {
                final selected = branding.fontThemeKey == font.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected
                        ? context.theme.colorScheme.primaryContainer
                        : context.theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                    borderRadius: VCareRadius.mdAll,
                    child: InkWell(
                      borderRadius: VCareRadius.mdAll,
                      onTap: brandingState.isBusy
                          ? null
                          : () => _selectFont(font.key),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 20,
                              color: selected
                                  ? context.theme.colorScheme.primary
                                  : context.theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    font.name,
                                    style: context.textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${font.display} / ${font.sans}',
                                    style: context.textTheme.bodySmall,
                                  ),
                                  Text(
                                    font.description,
                                    style: context.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsSectionCard(
            title: context.appLocalization.branding_logos_section,
            child: Column(
              children: [
                _LogoRow(
                  label: context.appLocalization.branding_primary_logo,
                  source: branding.logoUrl,
                  busy: brandingState.isBusy,
                  onUpload: () => _uploadLogo(isIcon: false),
                  onRemove: branding.logoUrl == null
                      ? null
                      : () => _removeLogo(isIcon: false),
                ),
                const SizedBox(height: 12),
                _LogoRow(
                  label: context.appLocalization.branding_icon_mark,
                  source: branding.iconUrl,
                  busy: brandingState.isBusy,
                  fallbackAsset: VCareAssets.vIcon,
                  onUpload: () => _uploadLogo(isIcon: true),
                  onRemove: branding.iconUrl == null
                      ? null
                      : () => _removeLogo(isIcon: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsSectionCard(
            title: context.appLocalization.text_scale,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
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
        ],
      ),
    );
  }

  Future<void> _applyPreset(TenantColorTheme theme) async {
    _primaryController.text = theme.primary;
    _secondaryController.text = theme.secondary;
    _accentController.text = theme.accent;
    await _saveColors();
  }

  Future<void> _saveColors() async {
    final primary = _primaryController.text.trim();
    final secondary = _secondaryController.text.trim();
    final accent = _accentController.text.trim();

    final primaryError = TenantBrandingValidators.validateHexColor(primary);
    final secondaryError =
        TenantBrandingValidators.validateHexColor(secondary);
    final accentError = TenantBrandingValidators.validateHexColor(accent);
    if (primaryError != null ||
        secondaryError != null ||
        accentError != null) {
      context.showVcareToast(
        title: context.appLocalization.branding_invalid_color,
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    await ref.read(tenantBrandingStateProvider.notifier).updateBranding(
          primaryColor: VCareHsl.normalizeHex(primary),
          secondaryColor: VCareHsl.normalizeHex(secondary),
          accentColor: VCareHsl.normalizeHex(accent),
          onCompleted: (data) {
            if (!mounted) return;
            context.showVcareToast(
              title: data == null
                  ? context.appLocalization.branding_save_failed
                  : context.appLocalization.branding_saved,
              variant: data == null
                  ? VcareToastVariant.destructive
                  : VcareToastVariant.success,
            );
          },
        );
  }

  Future<void> _selectFont(String key) async {
    await ref.read(tenantBrandingStateProvider.notifier).updateFontTheme(
          fontThemeKey: key,
          onCompleted: (data) {
            if (!mounted) return;
            context.showVcareToast(
              title: data == null
                  ? context.appLocalization.branding_save_failed
                  : context.appLocalization.branding_font_updated,
              variant: data == null
                  ? VcareToastVariant.destructive
                  : VcareToastVariant.success,
            );
          },
        );
  }

  Future<void> _reset() async {
    await ref.read(tenantBrandingStateProvider.notifier).resetToDefaults(
          onCompleted: (data) {
            if (!mounted) return;
            if (data != null) {
              _syncControllers(data);
            }
            context.showVcareToast(
              title: data == null
                  ? context.appLocalization.branding_save_failed
                  : context.appLocalization.branding_saved,
              variant: data == null
                  ? VcareToastVariant.destructive
                  : VcareToastVariant.success,
            );
          },
        );
  }

  Future<void> _uploadLogo({required bool isIcon}) async {
    await ImagePickerSourceSelectionBottomSheet.show<void>(
      context,
      onGalleryPick: () async {
        await _pickAndUpload(ImageSource.gallery, isIcon: isIcon);
      },
      onCameraPick: () async {
        await _pickAndUpload(ImageSource.camera, isIcon: isIcon);
      },
    );
  }

  Future<void> _pickAndUpload(
    ImageSource source, {
    required bool isIcon,
  }) async {
    final image = source == ImageSource.gallery
        ? await ImagePickerUtils.fromGallery()
        : await ImagePickerUtils.fromCamera();
    if (image == null || !mounted) return;

    final dataUrl = await _toDataUrl(image);
    if (!mounted) return;
    if (dataUrl == null) {
      context.showVcareToast(
        title: context.appLocalization.branding_save_failed,
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    await ref.read(tenantBrandingStateProvider.notifier).updateBranding(
          logoUrl: isIcon ? null : dataUrl,
          iconUrl: isIcon ? dataUrl : null,
          clearLogo: false,
          clearIcon: false,
          onCompleted: (data) {
            if (!mounted) return;
            context.showVcareToast(
              title: data == null
                  ? context.appLocalization.branding_save_failed
                  : context.appLocalization.branding_saved,
              variant: data == null
                  ? VcareToastVariant.destructive
                  : VcareToastVariant.success,
            );
          },
        );
  }

  Future<void> _removeLogo({required bool isIcon}) async {
    await ref.read(tenantBrandingStateProvider.notifier).updateBranding(
          clearLogo: !isIcon,
          clearIcon: isIcon,
          onCompleted: (data) {
            if (!mounted) return;
            context.showVcareToast(
              title: data == null
                  ? context.appLocalization.branding_save_failed
                  : context.appLocalization.branding_saved,
              variant: data == null
                  ? VcareToastVariant.destructive
                  : VcareToastVariant.success,
            );
          },
        );
  }

  Future<String?> _toDataUrl(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ??
          (file.path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg');
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  String _textScaleLabel(BuildContext context, {required AppTextScale scale}) {
    return switch (scale) {
      AppTextScale.small => context.appLocalization.text_scale_small,
      AppTextScale.normal => context.appLocalization.text_scale_default,
      AppTextScale.large => context.appLocalization.text_scale_large,
    };
  }
}

class _BrandingPreview extends StatelessWidget {
  const _BrandingPreview({required this.branding});

  final TenantBranding branding;

  @override
  Widget build(BuildContext context) {
    final primary =
        VCareHsl.colorFromHex(branding.primaryColor) ?? Colors.orange;
    final secondary =
        VCareHsl.colorFromHex(branding.secondaryColor) ?? Colors.teal;
    final accent =
        VCareHsl.colorFromHex(branding.accentColor) ?? Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TenantBrandedImage(
              source: branding.logoUrl,
              height: 36,
              fallbackAsset: VCareAssets.logo,
            ),
            const Spacer(),
            TenantBrandedImage(
              source: branding.iconUrl,
              width: 36,
              height: 36,
              fallbackAsset: VCareAssets.vIcon,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Swatch(color: primary, label: 'P'),
            const SizedBox(width: 8),
            _Swatch(color: secondary, label: 'S'),
            const SizedBox(width: 8),
            _Swatch(color: accent, label: 'A'),
            const Spacer(),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(backgroundColor: primary),
              child: const Text('Primary'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(foregroundColor: secondary),
              child: const Text('Secondary'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          VCareFontTheme.byKey(branding.fontThemeKey).name,
          style: context.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: VCareRadius.mdAll,
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.computeLuminance() > 0.55 ? Colors.black : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HexColorField extends StatelessWidget {
  const _HexColorField({
    required this.label,
    required this.controller,
    required this.enabled,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = VCareHsl.colorFromHex(controller.text);
    return TextField(
      controller: controller,
      enabled: enabled,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
        LengthLimitingTextInputFormatter(7),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? Colors.transparent,
              borderRadius: VCareRadius.smAll,
              border: Border.all(color: context.theme.dividerColor),
            ),
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      ),
    );
  }
}

class _LogoRow extends StatelessWidget {
  const _LogoRow({
    required this.label,
    required this.source,
    required this.busy,
    required this.onUpload,
    this.onRemove,
    this.fallbackAsset = VCareAssets.logo,
  });

  final String label;
  final String? source;
  final bool busy;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TenantBrandedImage(
          source: source,
          width: 56,
          height: 56,
          fallbackAsset: fallbackAsset,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : onUpload,
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: Text(context.appLocalization.branding_upload),
                  ),
                  if (onRemove != null)
                    TextButton(
                      onPressed: busy ? null : onRemove,
                      child: Text(context.appLocalization.branding_remove),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorPresetChip extends StatelessWidget {
  const _ColorPresetChip({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final TenantColorTheme theme;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.theme.colorScheme.primaryContainer
          : context.theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
      borderRadius: VCareRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniDot(color: VCareHsl.colorFromHex(theme.primary)!),
              const SizedBox(width: 4),
              _MiniDot(color: VCareHsl.colorFromHex(theme.secondary)!),
              const SizedBox(width: 8),
              Text(theme.name, style: context.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  const _MiniDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
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
        borderRadius: VCareRadius.xlAll,
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.textTheme.titleSmall),
            const SizedBox(height: 10),
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
      borderRadius: VCareRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
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
