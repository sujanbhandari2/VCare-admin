import 'package:flutter/material.dart';

/// Radius tokens — parity with web `index.css`.
abstract final class VCareRadius {
  static const double none = 0;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double full = 9999;

  /// Default component radius (`--radius`).
  static const double base = md;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);

  static BorderRadius sheetTop([double radius = xxl]) =>
      BorderRadius.vertical(top: Radius.circular(radius));
}
