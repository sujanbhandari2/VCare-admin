import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Tenant branding settings — parity with web `BrandingSettings` + font key.
class TenantBranding {
  const TenantBranding({
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

  static const defaults = TenantBranding(
    primaryColor: VCareColors.defaultPrimaryHex,
    secondaryColor: VCareColors.defaultSecondaryHex,
    accentColor: VCareColors.defaultAccentHex,
    fontThemeKey: VCareFontTheme.defaultKey,
  );

  VCareThemeInput get themeInput => VCareThemeInput(
        primaryHex: primaryColor,
        secondaryHex: secondaryColor,
        accentHex: accentColor,
        fontThemeKey: fontThemeKey,
      );

  TenantBranding copyWith({
    String? logoUrl,
    String? iconUrl,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? fontThemeKey,
    String? tenantId,
    bool clearLogo = false,
    bool clearIcon = false,
  }) {
    return TenantBranding(
      logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
      iconUrl: clearIcon ? null : (iconUrl ?? this.iconUrl),
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      fontThemeKey: fontThemeKey ?? this.fontThemeKey,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logoUrl': logoUrl,
      'iconUrl': iconUrl,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'fontThemeKey': fontThemeKey,
      'tenantId': tenantId,
    };
  }

  factory TenantBranding.fromJson(Map<String, dynamic> json) {
    return TenantBranding(
      logoUrl: _nullableString(json['logoUrl'] ?? json['logoDataUrl']),
      iconUrl: _nullableString(json['iconUrl'] ?? json['iconDataUrl']),
      primaryColor: _stringOr(
        json['primaryColor'],
        VCareColors.defaultPrimaryHex,
      ),
      secondaryColor: _stringOr(
        json['secondaryColor'],
        VCareColors.defaultSecondaryHex,
      ),
      accentColor: _stringOr(
        json['accentColor'],
        VCareColors.defaultAccentHex,
      ),
      fontThemeKey: _stringOr(
        json['fontThemeKey'],
        VCareFontTheme.defaultKey,
      ),
      tenantId: _nullableString(json['tenantId']),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _stringOr(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  @override
  bool operator ==(Object other) {
    return other is TenantBranding &&
        other.logoUrl == logoUrl &&
        other.iconUrl == iconUrl &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.accentColor == accentColor &&
        other.fontThemeKey == fontThemeKey &&
        other.tenantId == tenantId;
  }

  @override
  int get hashCode => Object.hash(
        logoUrl,
        iconUrl,
        primaryColor,
        secondaryColor,
        accentColor,
        fontThemeKey,
        tenantId,
      );
}

/// Curated color presets — parity with web `colorThemes.ts`.
class TenantColorTheme {
  const TenantColorTheme({
    required this.key,
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  final String key;
  final String name;
  final String description;
  final String primary;
  final String secondary;
  final String accent;

  static const all = <TenantColorTheme>[
    TenantColorTheme(
      key: 'sunset-clay',
      name: 'VCare Default',
      description: 'Warm clay with teal balance. The platform default.',
      primary: '#e06629',
      secondary: '#2f7f79',
      accent: '#f3f0ed',
    ),
    TenantColorTheme(
      key: 'ocean-pro',
      name: 'Soft & Patient Friendly',
      description: 'Calm blue with deep navy. Trusted and approachable.',
      primary: '#3B82F6',
      secondary: '#222C55',
      accent: '#F8FAFC',
    ),
    TenantColorTheme(
      key: 'forest-calm',
      name: 'Calm Care',
      description: 'Soft teal with sage green. Grounded and reassuring.',
      primary: '#5FA8A8',
      secondary: '#7ca07d',
      accent: '#F8F7F2',
    ),
  ];

  static TenantColorTheme? match({
    required String primary,
    required String secondary,
    required String accent,
  }) {
    String norm(String c) => c.trim().toLowerCase();
    for (final theme in all) {
      if (norm(theme.primary) == norm(primary) &&
          norm(theme.secondary) == norm(secondary) &&
          norm(theme.accent) == norm(accent)) {
        return theme;
      }
    }
    return null;
  }
}
