import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

class TenantBrandingModel {
  const TenantBrandingModel({
    this.logoUrl,
    this.iconUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.fontThemeKey = VCareFontTheme.defaultKey,
    this.tenantId,
  });

  final String? logoUrl;
  final String? iconUrl;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String fontThemeKey;
  final String? tenantId;

  factory TenantBrandingModel.fromSettingsJson(Map<String, dynamic> json) {
    final branding = _asMap(json['branding']);
    final theme = _asMap(json['theme']);
    final fontThemeKey = theme['fontThemeKey']?.toString().trim();

    return TenantBrandingModel(
      tenantId: json['tenantId']?.toString(),
      logoUrl: _nullableString(branding['primaryLogo']),
      iconUrl: _nullableString(branding['iconMark']),
      primaryColor: _colorOr(
        branding['primaryColor'],
        VCareColors.defaultPrimaryHex,
      ),
      secondaryColor: _colorOr(
        branding['secondaryColor'],
        VCareColors.defaultSecondaryHex,
      ),
      accentColor: _colorOr(
        branding['accentColor'],
        VCareColors.defaultAccentHex,
      ),
      fontThemeKey: (fontThemeKey == null || fontThemeKey.isEmpty)
          ? VCareFontTheme.defaultKey
          : fontThemeKey,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _colorOr(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return fallback;
    return text;
  }
}
