import 'package:flutter/material.dart';

/// VCare design tokens from vcareapp/src/index.css
class VCareColors {
  VCareColors._();

  static Color _hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1, h, s / 100, l / 100).toColor();

  static final background = _hsl(0, 0, 100);
  static final foreground = _hsl(181, 47, 17);

  static final card = _hsl(220, 16, 98.5);
  static final cardForeground = foreground;

  static final primary = _hsl(181, 100, 31);
  static final primaryForeground = Colors.white;

  static final secondary = _hsl(20, 82, 55);
  static final secondaryForeground = Colors.white;

  static final muted = _hsl(220, 14, 95);
  static final mutedForeground = _hsl(181, 25, 32);

  static final accent = _hsl(20, 82, 55);
  static final accentForeground = Colors.white;

  static final destructive = _hsl(0, 70, 55);
  static final destructiveForeground = Colors.white;

  static final border = _hsl(220, 13, 94);

  static const radius = 16.0;

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF009E9E),
      Color(0xFF0B6B6B),
    ],
  );

  static const gradientCardDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00B3B3),
      Color(0xFF0D7A7A),
    ],
  );
}
