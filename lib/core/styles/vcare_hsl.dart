import 'package:flutter/material.dart';

/// HSL helpers matching web `apply-branding.ts` / CSS `H S% L%` tokens.
class VCareHsl {
  const VCareHsl(this.h, this.s, this.l);

  final double h;
  final double s;
  final double l;

  Color toColor({double alpha = 1}) {
    return HSLColor.fromAHSL(
      alpha,
      ((h % 360) + 360) % 360,
      (s / 100).clamp(0.0, 1.0),
      (l / 100).clamp(0.0, 1.0),
    ).toColor();
  }

  VCareHsl copyWith({double? h, double? s, double? l}) {
    return VCareHsl(h ?? this.h, s ?? this.s, l ?? this.l);
  }

  /// Parses `#RRGGBB` into HSL parts (0–360, 0–100, 0–100).
  static VCareHsl? fromHex(String hex) {
    final m = hex.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(m)) return null;

    final r = int.parse(m.substring(0, 2), radix: 16) / 255;
    final g = int.parse(m.substring(2, 4), radix: 16) / 255;
    final b = int.parse(m.substring(4, 6), radix: 16) / 255;

    final max = [r, g, b].reduce((a, c) => a > c ? a : c);
    final min = [r, g, b].reduce((a, c) => a < c ? a : c);
    final l = (max + min) / 2;
    var h = 0.0;
    var s = 0.0;

    if (max != min) {
      final d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      if (max == r) {
        h = (g - b) / d + (g < b ? 6 : 0);
      } else if (max == g) {
        h = (b - r) / d + 2;
      } else {
        h = (r - g) / d + 4;
      }
      h *= 60;
    }

    return VCareHsl(h, s * 100, l * 100);
  }

  static Color colorFromHsl(double h, double s, double l, {double alpha = 1}) {
    return VCareHsl(h, s, l).toColor(alpha: alpha);
  }

  static Color? colorFromHex(String hex, {double alpha = 1}) {
    return fromHex(hex)?.toColor(alpha: alpha);
  }

  static String normalizeHex(String hex, {String fallback = '#e06629'}) {
    final m = hex.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(m)) return fallback;
    return '#${m.toLowerCase()}';
  }
}

/// Generated 50–800 tonal scale — parity with web `SCALE_LIGHTNESS`.
class VCareColorScale {
  const VCareColorScale({
    required this.s50,
    required this.s100,
    required this.s200,
    required this.s300,
    required this.s400,
    required this.s500,
    required this.s600,
    required this.s700,
    required this.s800,
  });

  final Color s50;
  final Color s100;
  final Color s200;
  final Color s300;
  final Color s400;
  final Color s500;
  final Color s600;
  final Color s700;
  final Color s800;

  Color operator [](int step) {
    return switch (step) {
      50 => s50,
      100 => s100,
      200 => s200,
      300 => s300,
      400 => s400,
      500 => s500,
      600 => s600,
      700 => s700,
      800 => s800,
      _ => s500,
    };
  }

  static const _lightness = <String, double>{
    '50': 97,
    '100': 92,
    '200': 84,
    '300': 72,
    '400': 62,
    '500': 50,
    '600': 42,
    '700': 34,
    '800': 24,
  };

  /// Builds a scale from a brand hex using the web algorithm.
  factory VCareColorScale.fromHex(String hex) {
    final parts = VCareHsl.fromHex(hex);
    if (parts == null) {
      return VCareColorScale.fromHex('#e06629');
    }

    Color stepColor(String step) {
      final targetL = _lightness[step]!;
      final lightness = step == '500' ? parts.l : targetL;
      final satScale = switch (step) {
        '50' => 0.5,
        '100' => 0.7,
        '200' => 0.85,
        '800' => 0.9,
        _ => 1.0,
      };
      return VCareHsl(parts.h, parts.s * satScale, lightness).toColor();
    }

    return VCareColorScale(
      s50: stepColor('50'),
      s100: stepColor('100'),
      s200: stepColor('200'),
      s300: stepColor('300'),
      s400: stepColor('400'),
      s500: stepColor('500'),
      s600: stepColor('600'),
      s700: stepColor('700'),
      s800: stepColor('800'),
    );
  }

  /// Static primary scale from web `index.css` (Vitafy orange).
  static final primaryDefault = VCareColorScale(
    s50: VCareHsl.colorFromHsl(17, 100, 97),
    s100: VCareHsl.colorFromHsl(17, 85, 92),
    s200: VCareHsl.colorFromHsl(17, 85, 85),
    s300: VCareHsl.colorFromHsl(17, 82, 72),
    s400: VCareHsl.colorFromHsl(17, 81, 64),
    s500: VCareHsl.colorFromHsl(17, 75, 52),
    s600: VCareHsl.colorFromHsl(17, 75, 52),
    s700: VCareHsl.colorFromHsl(17, 75, 52),
    s800: VCareHsl.colorFromHsl(17, 75, 45),
  );

  /// Static secondary scale from web `index.css` (Vitafy teal).
  static final secondaryDefault = VCareColorScale(
    s50: VCareHsl.colorFromHsl(183, 35, 97),
    s100: VCareHsl.colorFromHsl(183, 35, 92),
    s200: VCareHsl.colorFromHsl(183, 38, 82),
    s300: VCareHsl.colorFromHsl(183, 38, 55),
    s400: VCareHsl.colorFromHsl(183, 42, 45),
    s500: VCareHsl.colorFromHsl(183, 47, 32),
    s600: VCareHsl.colorFromHsl(183, 48, 25),
    s700: VCareHsl.colorFromHsl(183, 50, 22),
    s800: VCareHsl.colorFromHsl(183, 50, 18),
  );

  static final success = VCareColorScale(
    s50: VCareHsl.colorFromHsl(145, 80, 96),
    s100: VCareHsl.colorFromHsl(145, 75, 90),
    s200: VCareHsl.colorFromHsl(145, 70, 78),
    s300: VCareHsl.colorFromHsl(145, 68, 62),
    s400: VCareHsl.colorFromHsl(152, 48, 44),
    s500: VCareHsl.colorFromHsl(152, 50, 34),
    s600: VCareHsl.colorFromHsl(152, 55, 28),
    s700: VCareHsl.colorFromHsl(145, 68, 26),
    s800: VCareHsl.colorFromHsl(145, 65, 20),
  );

  static final warning = VCareColorScale(
    s50: VCareHsl.colorFromHsl(45, 100, 96),
    s100: VCareHsl.colorFromHsl(45, 95, 90),
    s200: VCareHsl.colorFromHsl(45, 92, 78),
    s300: VCareHsl.colorFromHsl(45, 90, 65),
    s400: VCareHsl.colorFromHsl(42, 88, 55),
    s500: VCareHsl.colorFromHsl(38, 92, 50),
    s600: VCareHsl.colorFromHsl(32, 95, 44),
    s700: VCareHsl.colorFromHsl(26, 90, 38),
    s800: VCareHsl.colorFromHsl(22, 82, 31),
  );

  static final danger = VCareColorScale(
    s50: VCareHsl.colorFromHsl(0, 85, 97),
    s100: VCareHsl.colorFromHsl(0, 80, 93),
    s200: VCareHsl.colorFromHsl(0, 75, 85),
    s300: VCareHsl.colorFromHsl(0, 72, 72),
    s400: VCareHsl.colorFromHsl(4, 62, 56),
    s500: VCareHsl.colorFromHsl(4, 64, 48),
    s600: VCareHsl.colorFromHsl(4, 68, 40),
    s700: VCareHsl.colorFromHsl(0, 78, 36),
    s800: VCareHsl.colorFromHsl(0, 75, 29),
  );

  static final info = VCareColorScale(
    s50: VCareHsl.colorFromHsl(205, 100, 97),
    s100: VCareHsl.colorFromHsl(205, 95, 92),
    s200: VCareHsl.colorFromHsl(205, 90, 82),
    s300: VCareHsl.colorFromHsl(205, 85, 68),
    s400: VCareHsl.colorFromHsl(205, 62, 50),
    s500: VCareHsl.colorFromHsl(205, 64, 40),
    s600: VCareHsl.colorFromHsl(205, 68, 34),
    s700: VCareHsl.colorFromHsl(205, 85, 30),
    s800: VCareHsl.colorFromHsl(205, 80, 24),
  );

  static final body = VCareColorScale(
    s50: VCareHsl.colorFromHsl(30, 40, 98),
    s100: VCareHsl.colorFromHsl(30, 30, 95),
    s200: VCareHsl.colorFromHsl(30, 25, 88),
    s300: VCareHsl.colorFromHsl(200, 14, 75),
    s400: VCareHsl.colorFromHsl(200, 15, 55),
    s500: VCareHsl.colorFromHsl(200, 15, 40),
    s600: VCareHsl.colorFromHsl(200, 25, 28),
    s700: VCareHsl.colorFromHsl(200, 40, 18),
    s800: VCareHsl.colorFromHsl(200, 50, 12),
  );
}
