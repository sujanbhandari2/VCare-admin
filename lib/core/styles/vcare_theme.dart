import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vcare_admin/core/styles/vcare_button_styles.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_hsl.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_shadows.dart';

export 'package:vcare_admin/core/styles/vcare_hsl.dart'
    show VCareHsl, VCareColorScale;

/// Input used to build a branded [ThemeData] — mirrors web branding + font key.
class VCareThemeInput {
  const VCareThemeInput({
    this.primaryHex = VCareColors.defaultPrimaryHex,
    this.secondaryHex = VCareColors.defaultSecondaryHex,
    this.accentHex = VCareColors.defaultAccentHex,
    this.fontThemeKey = 'vitafy',
  });

  final String primaryHex;
  final String secondaryHex;
  final String accentHex;
  final String fontThemeKey;

  static const defaults = VCareThemeInput();
}

/// Font preset metadata — parity with web `fontThemes.ts`.
class VCareFontTheme {
  const VCareFontTheme({
    required this.key,
    required this.name,
    required this.description,
    required this.display,
    required this.sans,
  });

  final String key;
  final String name;
  final String description;
  final String display;
  final String sans;

  static const vitafy = VCareFontTheme(
    key: 'vitafy',
    name: 'Vcare Font',
    description:
        'Clean geometric headings paired with a friendly humanist sans.',
    display: 'Heebo',
    sans: 'Open Sans',
  );

  static const modernTech = VCareFontTheme(
    key: 'modern-tech',
    name: 'Modern Tech',
    description: 'Geometric display with a clean neutral body for product UIs.',
    display: 'Space Grotesk',
    sans: 'Manrope',
  );

  static const editorial = VCareFontTheme(
    key: 'editorial',
    name: 'Editorial',
    description:
        'Modern serif with strong contrast for magazine-style layouts.',
    display: 'Fraunces',
    sans: 'Inter',
  );

  static const classic = VCareFontTheme(
    key: 'classic',
    name: 'Classic',
    description: 'Timeless system stack — fast loading, no web fonts.',
    display: 'Georgia',
    sans: 'System Sans',
  );

  static const minimalMono = VCareFontTheme(
    key: 'minimal-mono',
    name: 'Clash Display',
    description: 'Bold geometric display paired with a friendly humanist sans.',
    display: 'Clash Display',
    sans: 'Plus Jakarta Sans',
  );

  static const all = <VCareFontTheme>[
    vitafy,
    modernTech,
    editorial,
    classic,
    minimalMono,
  ];

  static const defaultKey = 'vitafy';

  static VCareFontTheme byKey(String? key) {
    return all.firstWhere((t) => t.key == key, orElse: () => vitafy);
  }
}

class VCareTheme {
  VCareTheme._();

  static ThemeData light({
    VCareThemeInput input = VCareThemeInput.defaults,
    double contrastLevel = 0.0,
  }) {
    final primary =
        VCareHsl.colorFromHex(input.primaryHex) ?? VCareColors.primary;
    final secondary =
        VCareHsl.colorFromHex(input.secondaryHex) ?? VCareColors.secondary;
    final accentParts = VCareHsl.fromHex(input.accentHex);
    final accent = accentParts?.toColor() ?? VCareColors.accent;
    final accentForeground = accentParts != null && accentParts.l > 60
        ? VCareHsl(accentParts.h, accentParts.s.clamp(0, 50), 18).toColor()
        : Colors.white;

    final primaryScale = VCareColorScale.fromHex(input.primaryHex);
    final secondaryScale = VCareColorScale.fromHex(input.secondaryHex);
    final primaryHsl = VCareHsl.fromHex(input.primaryHex);

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: VCareColors.primaryForeground,
      primaryContainer: primaryScale.s100,
      onPrimaryContainer: primaryScale.s800,
      secondary: secondary,
      onSecondary: VCareColors.secondaryForeground,
      secondaryContainer: secondaryScale.s100,
      onSecondaryContainer: secondaryScale.s800,
      tertiary: accent,
      onTertiary: accentForeground,
      tertiaryContainer: accent,
      onTertiaryContainer: accentForeground,
      error: VCareColors.destructive,
      onError: VCareColors.destructiveForeground,
      errorContainer: VCareColorScale.danger.s100,
      onErrorContainer: VCareColorScale.danger.s800,
      surface: VCareColors.background,
      onSurface: VCareColors.foreground,
      surfaceContainerLowest: VCareColors.background,
      surfaceContainerLow: VCareColors.card,
      surfaceContainer: VCareColors.muted,
      surfaceContainerHigh: VCareColors.card,
      surfaceContainerHighest: VCareColors.card,
      onSurfaceVariant: VCareColors.mutedForeground,
      outline: VCareColors.border,
      outlineVariant: VCareColors.input,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: VCareColors.foreground,
      onInverseSurface: VCareColors.background,
      inversePrimary: primaryScale.s200,
    );

    final fontTheme = VCareFontTheme.byKey(input.fontThemeKey);
    final textTheme = _buildTextTheme(
      fontTheme: fontTheme,
      foreground: VCareColors.foreground,
      mutedForeground: VCareColors.mutedForeground,
    );

    final extension = VCareThemeExtension(
      primary: primary,
      secondary: secondary,
      accent: accent,
      accentForeground: accentForeground,
      background: VCareColors.background,
      foreground: VCareColors.foreground,
      card: VCareColors.card,
      muted: VCareColors.muted,
      mutedForeground: VCareColors.mutedForeground,
      border: VCareColors.border,
      input: VCareColors.input,
      ring: primaryHsl?.toColor() ?? VCareColors.ring,
      success: VCareColors.success,
      warning: VCareColors.warning,
      info: VCareColors.info,
      destructive: VCareColors.destructive,
      tealLight: secondaryScale.s50,
      terracottaLight: primaryHsl != null
          ? VCareHsl(primaryHsl.h, primaryHsl.s.clamp(0, 70), 94).toColor()
          : VCareColors.terracottaLight,
      filterPanel: VCareColors.filterPanel,
      tableHeader: VCareColors.tableHeader,
      sectionSurface: VCareColors.sectionSurface,
      primaryScale: primaryScale,
      secondaryScale: secondaryScale,
      successScale: VCareColorScale.success,
      warningScale: VCareColorScale.warning,
      dangerScale: VCareColorScale.danger,
      infoScale: VCareColorScale.info,
      primaryShadow: VCareShadows.primary(primary),
      secondaryShadow: VCareShadows.secondary(secondary),
      gradientCard: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondary, secondaryScale.s700],
      ),
      gradientHero: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondary, secondary.withValues(alpha: 0.85)],
      ),
      gradientTeal: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondary, secondaryScale.s400],
      ),
      gradientWarm: VCareColors.gradientWarm,
      gradientSunset: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondary, primary],
      ),
      gradientAction: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryScale.s400],
      ),
      fontThemeKey: fontTheme.key,
      displayFontFamily: fontTheme.display,
      bodyFontFamily: fontTheme.sans,
    );

    final radius = BorderRadius.circular(VCareRadius.md);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: VCareColors.background,
      canvasColor: VCareColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardTheme: CardThemeData(
        color: VCareColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VCareRadius.lg),
          side: BorderSide(color: VCareColors.border),
        ),
      ),
      dividerColor: VCareColors.border,
      dividerTheme: DividerThemeData(
        color: VCareColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: VCareColors.background,
        foregroundColor: VCareColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: VCareButtonStyles.filled(
          background: primary,
          foreground: Colors.white,
          labelStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: VCareButtonStyles.filled(
          background: primary,
          foreground: Colors.white,
          labelStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: VCareButtonStyles.outlined(
          foreground: VCareColors.foreground,
          border: VCareColors.input,
          background: VCareColors.background,
          hoverBackground: accent,
          hoverForeground: accentForeground,
          labelStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: VCareButtonStyles.ghost(
          foreground: primary,
          hoverBackground: accent,
          labelStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: VCareColors.input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: VCareColors.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: VCareColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: VCareColors.destructive, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: VCareColors.mutedForeground,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VCareColors.muted,
        selectedColor: primaryScale.s100,
        disabledColor: VCareColors.muted,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VCareRadius.full),
          side: BorderSide(color: VCareColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: VCareColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VCareRadius.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: VCareColors.background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(VCareRadius.xxl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: VCareColors.foreground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VCareRadius.md),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: VCareColors.mutedForeground,
        indicatorColor: primary,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VCareRadius.lg),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      extensions: [extension],
    );
  }

  /// Dark theme retained for ThemeData API compatibility but unused —
  /// the app is light-only to match the web console.
  static ThemeData dark({
    VCareThemeInput input = VCareThemeInput.defaults,
    double contrastLevel = 0.0,
  }) {
    return light(input: input, contrastLevel: contrastLevel);
  }

  static TextTheme _buildTextTheme({
    required VCareFontTheme fontTheme,
    required Color foreground,
    required Color mutedForeground,
  }) {
    TextStyle bodyBase({
      double size = 14,
      FontWeight weight = FontWeight.w400,
      Color? color,
      double height = 1.5,
      double? letterSpacing,
    }) {
      final resolvedColor = color ?? foreground;
      try {
        return switch (fontTheme.key) {
          'modern-tech' => GoogleFonts.manrope(
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
          'editorial' => GoogleFonts.inter(
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
          'classic' => TextStyle(
            fontFamily: '.SF Pro Text',
            fontFamilyFallback: const [
              'Segoe UI',
              'Roboto',
              'Helvetica Neue',
              'Arial',
              'sans-serif',
            ],
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
          'minimal-mono' => GoogleFonts.plusJakartaSans(
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
          _ => GoogleFonts.openSans(
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
        };
      } catch (_) {
        return GoogleFonts.openSans(
          fontSize: size,
          fontWeight: weight,
          color: resolvedColor,
          height: height,
          letterSpacing: letterSpacing,
        );
      }
    }

    TextStyle displayBase({
      double size = 24,
      FontWeight weight = FontWeight.w700,
      Color? color,
      double height = 1.25,
      double letterSpacing = -0.25,
    }) {
      final resolvedColor = color ?? foreground;
      try {
        return switch (fontTheme.key) {
          'modern-tech' => GoogleFonts.spaceGrotesk(
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
          'editorial' => GoogleFonts.fraunces(
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
          'classic' => TextStyle(
            fontFamily: 'Georgia',
            fontFamilyFallback: const ['Times New Roman', 'serif'],
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
          // Clash Display is not on Google Fonts — fall back to Space Grotesk
          // as the web CSS stack does.
          'minimal-mono' => GoogleFonts.spaceGrotesk(
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
          _ => GoogleFonts.heebo(
            fontSize: size,
            fontWeight: weight,
            color: resolvedColor,
            height: height,
            letterSpacing: letterSpacing,
          ),
        };
      } catch (_) {
        return GoogleFonts.heebo(
          fontSize: size,
          fontWeight: weight,
          color: resolvedColor,
          height: height,
          letterSpacing: letterSpacing,
        );
      }
    }

    return TextTheme(
      displayLarge: displayBase(size: 40, weight: FontWeight.w700),
      displayMedium: displayBase(size: 36, weight: FontWeight.w700),
      displaySmall: displayBase(size: 32, weight: FontWeight.w700),
      headlineLarge: displayBase(size: 28, weight: FontWeight.w700),
      headlineMedium: displayBase(size: 24, weight: FontWeight.w700),
      headlineSmall: displayBase(
        size: 20,
        weight: FontWeight.w600,
        height: 1.375,
      ),
      titleLarge: displayBase(size: 20, weight: FontWeight.w700),
      titleMedium: bodyBase(size: 16, weight: FontWeight.w600),
      titleSmall: bodyBase(size: 14, weight: FontWeight.w600),
      bodyLarge: bodyBase(size: 16, height: 1.625),
      bodyMedium: bodyBase(size: 14),
      bodySmall: bodyBase(size: 12, color: mutedForeground),
      labelLarge: bodyBase(size: 14, weight: FontWeight.w600, height: 1),
      labelMedium: bodyBase(size: 12, weight: FontWeight.w500, height: 1),
      labelSmall: bodyBase(
        size: 10,
        weight: FontWeight.w600,
        color: mutedForeground,
        letterSpacing: 0.1,
      ),
    );
  }
}

class VCareThemeExtension extends ThemeExtension<VCareThemeExtension> {
  const VCareThemeExtension({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.accentForeground,
    required this.background,
    required this.foreground,
    required this.card,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.success,
    required this.warning,
    required this.info,
    required this.destructive,
    required this.tealLight,
    required this.terracottaLight,
    required this.filterPanel,
    required this.tableHeader,
    required this.sectionSurface,
    required this.primaryScale,
    required this.secondaryScale,
    required this.successScale,
    required this.warningScale,
    required this.dangerScale,
    required this.infoScale,
    required this.primaryShadow,
    required this.secondaryShadow,
    required this.gradientCard,
    required this.gradientHero,
    required this.gradientTeal,
    required this.gradientWarm,
    required this.gradientSunset,
    required this.gradientAction,
    required this.fontThemeKey,
    required this.displayFontFamily,
    required this.bodyFontFamily,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color accentForeground;
  final Color background;
  final Color foreground;
  final Color card;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color success;
  final Color warning;
  final Color info;
  final Color destructive;
  final Color tealLight;
  final Color terracottaLight;
  final Color filterPanel;
  final Color tableHeader;
  final Color sectionSurface;
  final VCareColorScale primaryScale;
  final VCareColorScale secondaryScale;
  final VCareColorScale successScale;
  final VCareColorScale warningScale;
  final VCareColorScale dangerScale;
  final VCareColorScale infoScale;
  final List<BoxShadow> primaryShadow;
  final List<BoxShadow> secondaryShadow;
  final LinearGradient gradientCard;
  final LinearGradient gradientHero;
  final LinearGradient gradientTeal;
  final LinearGradient gradientWarm;
  final LinearGradient gradientSunset;
  final LinearGradient gradientAction;
  final String fontThemeKey;
  final String displayFontFamily;
  final String bodyFontFamily;

  static final light = VCareTheme.light().extension<VCareThemeExtension>()!;

  /// Deprecated alias — app is light-only.
  static final dark = light;

  @override
  VCareThemeExtension copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? accentForeground,
    Color? background,
    Color? foreground,
    Color? card,
    Color? muted,
    Color? mutedForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? success,
    Color? warning,
    Color? info,
    Color? destructive,
    Color? tealLight,
    Color? terracottaLight,
    Color? filterPanel,
    Color? tableHeader,
    Color? sectionSurface,
    VCareColorScale? primaryScale,
    VCareColorScale? secondaryScale,
    VCareColorScale? successScale,
    VCareColorScale? warningScale,
    VCareColorScale? dangerScale,
    VCareColorScale? infoScale,
    List<BoxShadow>? primaryShadow,
    List<BoxShadow>? secondaryShadow,
    LinearGradient? gradientCard,
    LinearGradient? gradientHero,
    LinearGradient? gradientTeal,
    LinearGradient? gradientWarm,
    LinearGradient? gradientSunset,
    LinearGradient? gradientAction,
    String? fontThemeKey,
    String? displayFontFamily,
    String? bodyFontFamily,
  }) {
    return VCareThemeExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      destructive: destructive ?? this.destructive,
      tealLight: tealLight ?? this.tealLight,
      terracottaLight: terracottaLight ?? this.terracottaLight,
      filterPanel: filterPanel ?? this.filterPanel,
      tableHeader: tableHeader ?? this.tableHeader,
      sectionSurface: sectionSurface ?? this.sectionSurface,
      primaryScale: primaryScale ?? this.primaryScale,
      secondaryScale: secondaryScale ?? this.secondaryScale,
      successScale: successScale ?? this.successScale,
      warningScale: warningScale ?? this.warningScale,
      dangerScale: dangerScale ?? this.dangerScale,
      infoScale: infoScale ?? this.infoScale,
      primaryShadow: primaryShadow ?? this.primaryShadow,
      secondaryShadow: secondaryShadow ?? this.secondaryShadow,
      gradientCard: gradientCard ?? this.gradientCard,
      gradientHero: gradientHero ?? this.gradientHero,
      gradientTeal: gradientTeal ?? this.gradientTeal,
      gradientWarm: gradientWarm ?? this.gradientWarm,
      gradientSunset: gradientSunset ?? this.gradientSunset,
      gradientAction: gradientAction ?? this.gradientAction,
      fontThemeKey: fontThemeKey ?? this.fontThemeKey,
      displayFontFamily: displayFontFamily ?? this.displayFontFamily,
      bodyFontFamily: bodyFontFamily ?? this.bodyFontFamily,
    );
  }

  @override
  VCareThemeExtension lerp(
    ThemeExtension<VCareThemeExtension>? other,
    double t,
  ) {
    if (other is! VCareThemeExtension) return this;
    if (t < 0.5) return this;
    return other;
  }
}

extension VCareThemeContext on BuildContext {
  VCareThemeExtension get vcare =>
      Theme.of(this).extension<VCareThemeExtension>() ??
      VCareThemeExtension.light;
}
