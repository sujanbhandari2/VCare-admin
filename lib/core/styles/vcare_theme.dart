import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vcare_colors.dart';

class VCareTheme {
  VCareTheme._();

  static ThemeData light({double contrastLevel = 0.0}) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: VCareColors.primary,
      onPrimary: VCareColors.primaryForeground,
      secondary: VCareColors.secondary,
      onSecondary: VCareColors.secondaryForeground,
      error: VCareColors.destructive,
      onError: VCareColors.destructiveForeground,
      surface: VCareColors.background,
      onSurface: VCareColors.foreground,
      surfaceContainerHighest: VCareColors.card,
      onSurfaceVariant: VCareColors.mutedForeground,
      outline: VCareColors.border,
    );

    final nunito = GoogleFonts.nunitoTextTheme();
    final quicksand = GoogleFonts.quicksand();

    final textTheme = nunito.copyWith(
      headlineMedium: quicksand.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: VCareColors.foreground,
        letterSpacing: -0.25,
      ),
      titleLarge: quicksand.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: VCareColors.foreground,
        letterSpacing: -0.25,
      ),
      titleMedium: nunito.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: VCareColors.foreground,
      ),
      bodyMedium: nunito.bodyMedium?.copyWith(color: VCareColors.foreground),
      bodySmall: nunito.bodySmall?.copyWith(color: VCareColors.mutedForeground),
      labelSmall: nunito.labelSmall?.copyWith(
        color: VCareColors.mutedForeground,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: VCareColors.background,
      canvasColor: VCareColors.background,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: VCareColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VCareColors.radius),
          side: BorderSide(color: VCareColors.border),
        ),
      ),
      dividerColor: VCareColors.border,
      extensions: const [VCareThemeExtension.light],
    );
  }

  static ThemeData dark({double contrastLevel = 0.0}) {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: VCareColors.primary,
      onPrimary: VCareColors.primaryForeground,
      secondary: VCareColors.secondary,
      onSecondary: VCareColors.secondaryForeground,
      error: VCareColors.destructive,
      onError: VCareColors.destructiveForeground,
      surface: const Color(0xFF0F1A1A),
      onSurface: const Color(0xFFE8F4F4),
      surfaceContainerHighest: const Color(0xFF1A2626),
      onSurfaceVariant: const Color(0xFF9BB5B5),
      outline: const Color(0xFF2A3838),
    );

    final nunito = GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme);
    final quicksand = GoogleFonts.quicksand();

    final textTheme = nunito.copyWith(
      headlineMedium: quicksand.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.25,
      ),
      titleLarge: quicksand.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VCareColors.radius),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      dividerColor: colorScheme.outline,
      extensions: const [VCareThemeExtension.dark],
    );
  }
}

class VCareThemeExtension extends ThemeExtension<VCareThemeExtension> {
  const VCareThemeExtension({
    required this.card,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.border,
    required this.success,
    required this.tealLight,
    required this.terracottaLight,
    required this.gradientCard,
    required this.gradientHero,
    required this.gradientTeal,
    required this.gradientWarm,
    required this.gradientSunset,
    required this.gradientAction,
  });

  final Color card;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color border;
  final Color success;
  final Color tealLight;
  final Color terracottaLight;
  final LinearGradient gradientCard;
  final LinearGradient gradientHero;
  final LinearGradient gradientTeal;
  final LinearGradient gradientWarm;
  final LinearGradient gradientSunset;
  final LinearGradient gradientAction;

  static const light = VCareThemeExtension(
    card: Color(0xFFFAFBFC),
    muted: Color(0xFFF1F2F4),
    mutedForeground: Color(0xFF3D5C5C),
    accent: Color(0xFFE86F33),
    border: Color(0xFFEEF0F2),
    success: Color(0xFF29A36F),
    tealLight: Color(0xFFE8F4F4),
    terracottaLight: Color(0xFFFDF4EE),
    gradientCard: VCareColors.gradientCard,
    gradientHero: VCareColors.gradientHero,
    gradientTeal: VCareColors.gradientTeal,
    gradientWarm: VCareColors.gradientWarm,
    gradientSunset: VCareColors.gradientSunset,
    gradientAction: VCareColors.gradientAction,
  );

  static const dark = VCareThemeExtension(
    card: Color(0xFF1A2626),
    muted: Color(0xFF243030),
    mutedForeground: Color(0xFF9BB5B5),
    accent: Color(0xFFE86F33),
    border: Color(0xFF2A3838),
    success: Color(0xFF29A36F),
    tealLight: Color(0xFF1A2626),
    terracottaLight: Color(0xFF2A2420),
    gradientCard: VCareColors.gradientCardDark,
    gradientHero: VCareColors.gradientHero,
    gradientTeal: VCareColors.gradientTeal,
    gradientWarm: VCareColors.gradientWarm,
    gradientSunset: VCareColors.gradientSunset,
    gradientAction: VCareColors.gradientAction,
  );

  @override
  VCareThemeExtension copyWith({
    Color? card,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? border,
    Color? success,
    Color? tealLight,
    Color? terracottaLight,
    LinearGradient? gradientCard,
    LinearGradient? gradientHero,
    LinearGradient? gradientTeal,
    LinearGradient? gradientWarm,
    LinearGradient? gradientSunset,
    LinearGradient? gradientAction,
  }) {
    return VCareThemeExtension(
      card: card ?? this.card,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      success: success ?? this.success,
      tealLight: tealLight ?? this.tealLight,
      terracottaLight: terracottaLight ?? this.terracottaLight,
      gradientCard: gradientCard ?? this.gradientCard,
      gradientHero: gradientHero ?? this.gradientHero,
      gradientTeal: gradientTeal ?? this.gradientTeal,
      gradientWarm: gradientWarm ?? this.gradientWarm,
      gradientSunset: gradientSunset ?? this.gradientSunset,
      gradientAction: gradientAction ?? this.gradientAction,
    );
  }

  @override
  VCareThemeExtension lerp(
    ThemeExtension<VCareThemeExtension>? other,
    double t,
  ) {
    if (other is! VCareThemeExtension) return this;
    return other;
  }
}

extension VCareThemeContext on BuildContext {
  VCareThemeExtension get vcare =>
      Theme.of(this).extension<VCareThemeExtension>()!;
}
