import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_hsl.dart';

/// Shadow tokens — parity with web `index.css`.
abstract final class VCareShadows {
  static const none = <BoxShadow>[];

  static final xs = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static final sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 2,
      offset: const Offset(0, 1),
      spreadRadius: -1,
    ),
  ];

  static final md = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 6,
      offset: const Offset(0, 4),
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  static final lg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 15,
      offset: const Offset(0, 10),
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 6,
      offset: const Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  static final xl = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 25,
      offset: const Offset(0, 20),
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  static List<BoxShadow> primary(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> secondary(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> primaryFromHex(String hex) {
    final color =
        VCareHsl.colorFromHex(hex) ?? VCareHsl.colorFromHsl(17, 74, 52);
    return primary(color);
  }

  static List<BoxShadow> secondaryFromHex(String hex) {
    final color =
        VCareHsl.colorFromHex(hex) ?? VCareHsl.colorFromHsl(176, 45, 34);
    return secondary(color);
  }
}
