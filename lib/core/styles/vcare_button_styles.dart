import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Size tokens — parity with the web `buttonVariants` sizes in
/// `src/components/ui/button.tsx`.
enum VCareButtonSize {
  /// Web `size="sm"` — `h-8 px-3 text-xs`.
  sm(height: 32, horizontalPadding: 12, fontSize: 12),

  /// Web default size — `h-10 px-4 py-2`.
  md(height: 40, horizontalPadding: 16, fontSize: 14),

  /// Web full-width submit pattern — `h-11` kept on the default type scale.
  lg(height: 44, horizontalPadding: 24, fontSize: 14);

  const VCareButtonSize({
    required this.height,
    required this.horizontalPadding,
    required this.fontSize,
  });

  final double height;
  final double horizontalPadding;
  final double fontSize;

  EdgeInsets get padding => EdgeInsets.symmetric(horizontal: horizontalPadding);
}

/// Button styles mirroring the web `buttonVariants` cva.
///
/// Web renders every button flat, keeps labels at `text-sm font-medium`, moves
/// solid fills to the `600`/`700` brand steps on hover/press, and fades
/// disabled buttons to 50% opacity instead of greying them out.
abstract final class VCareButtonStyles {
  /// Web `[&_svg]:size-4`.
  static const double iconSize = 16;

  /// Web `disabled:opacity-50`.
  static const double disabledOpacity = 0.5;

  /// Web `font-medium`.
  static const FontWeight fontWeight = FontWeight.w500;

  /// Web `transition-all duration-200`.
  static const Duration _transition = Duration(milliseconds: 200);

  /// Lightness of the `600` / `700` scale steps (web `SCALE_LIGHTNESS`).
  static const double _hoverLightness = 42;
  static const double _pressedLightness = 34;

  /// Web `variant="default"` — solid brand fill with an on-brand label.
  ///
  /// Hover and press default to the `600`/`700` steps of [background] so
  /// tenant-branded buttons shade themselves; pass [hoverBackground] and
  /// [pressedBackground] for the few CTAs where web hardcodes exact hexes.
  ///
  /// Set [dimWhenDisabled] to `false` while a button is showing a spinner so
  /// the fill keeps full strength even though taps are blocked.
  static ButtonStyle filled({
    required Color background,
    required Color foreground,
    Color? hoverBackground,
    Color? pressedBackground,
    VCareButtonSize size = VCareButtonSize.md,
    TextStyle? labelStyle,
    double? fontSize,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool dimWhenDisabled = true,
  }) {
    return _style(
      size: size,
      labelStyle: labelStyle,
      fontSize: fontSize,
      borderRadius: borderRadius,
      padding: padding,
      backgroundColor: _interactive(
        base: background,
        hovered: hoverBackground ?? _step(background, _hoverLightness),
        pressed: pressedBackground ?? _step(background, _pressedLightness),
        dimWhenDisabled: dimWhenDisabled,
      ),
      foregroundColor: _flat(foreground, dimWhenDisabled: dimWhenDisabled),
    );
  }

  /// Web `variant="outline"` — neutral hairline border on the page background.
  static ButtonStyle outlined({
    required Color foreground,
    required Color border,
    required Color background,
    required Color hoverBackground,
    required Color hoverForeground,
    VCareButtonSize size = VCareButtonSize.md,
    TextStyle? labelStyle,
    double? fontSize,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool dimWhenDisabled = true,
  }) {
    return _style(
      size: size,
      labelStyle: labelStyle,
      fontSize: fontSize,
      borderRadius: borderRadius,
      padding: padding,
      backgroundColor: _interactive(
        base: background,
        hovered: hoverBackground,
        pressed: hoverBackground,
        dimWhenDisabled: dimWhenDisabled,
      ),
      foregroundColor: _interactive(
        base: foreground,
        hovered: hoverForeground,
        pressed: hoverForeground,
        dimWhenDisabled: dimWhenDisabled,
      ),
      side: _side(border, width: 1, dimWhenDisabled: dimWhenDisabled),
    );
  }

  /// Web `variant="outline-primary"` — 2px tinted border that fills with the
  /// `50`/`100` steps of its own colour on hover and press.
  static ButtonStyle outlinedTinted({
    required Color color,
    VCareButtonSize size = VCareButtonSize.md,
    TextStyle? labelStyle,
    double? fontSize,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool dimWhenDisabled = true,
  }) {
    return _style(
      size: size,
      labelStyle: labelStyle,
      fontSize: fontSize,
      borderRadius: borderRadius,
      padding: padding,
      backgroundColor: _interactive(
        base: Colors.transparent,
        hovered: color.withValues(alpha: 0.08),
        pressed: color.withValues(alpha: 0.14),
        dimWhenDisabled: false,
      ),
      foregroundColor: _flat(color, dimWhenDisabled: dimWhenDisabled),
      side: _side(color, width: 2, dimWhenDisabled: dimWhenDisabled),
    );
  }

  /// Web `variant="ghost"` / `variant="link"` — no chrome until hovered.
  static ButtonStyle ghost({
    required Color foreground,
    required Color hoverBackground,
    Color? hoverForeground,
    VCareButtonSize size = VCareButtonSize.md,
    TextStyle? labelStyle,
    double? fontSize,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool dimWhenDisabled = true,
  }) {
    return _style(
      size: size,
      labelStyle: labelStyle,
      fontSize: fontSize,
      borderRadius: borderRadius,
      padding: padding,
      backgroundColor: _interactive(
        base: Colors.transparent,
        hovered: hoverBackground,
        pressed: hoverBackground,
        dimWhenDisabled: false,
      ),
      foregroundColor: _interactive(
        base: foreground,
        hovered: hoverForeground ?? foreground,
        pressed: hoverForeground ?? foreground,
        dimWhenDisabled: dimWhenDisabled,
      ),
    );
  }

  static ButtonStyle _style({
    required VCareButtonSize size,
    required WidgetStateProperty<Color?> backgroundColor,
    required WidgetStateProperty<Color?> foregroundColor,
    WidgetStateProperty<BorderSide?>? side,
    TextStyle? labelStyle,
    double? fontSize,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return ButtonStyle(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      iconColor: foregroundColor,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: side,
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      iconSize: const WidgetStatePropertyAll(iconSize),
      minimumSize: WidgetStatePropertyAll(Size(64, size.height)),
      padding: WidgetStatePropertyAll(padding ?? size.padding),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: borderRadius ?? VCareRadius.mdAll),
      ),
      textStyle: WidgetStatePropertyAll(
        (labelStyle ?? const TextStyle()).copyWith(
          fontSize: fontSize ?? size.fontSize,
          fontWeight: fontWeight,
        ),
      ),
      animationDuration: _transition,
    );
  }

  static WidgetStateProperty<Color?> _interactive({
    required Color base,
    required Color hovered,
    required Color pressed,
    required bool dimWhenDisabled,
  }) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return dimWhenDisabled ? _dim(base) : base;
      }
      if (states.contains(WidgetState.pressed)) return pressed;
      if (states.contains(WidgetState.hovered)) return hovered;
      return base;
    });
  }

  static WidgetStateProperty<Color?> _flat(
    Color color, {
    required bool dimWhenDisabled,
  }) {
    return WidgetStateProperty.resolveWith((states) {
      final disabled = states.contains(WidgetState.disabled);
      return disabled && dimWhenDisabled ? _dim(color) : color;
    });
  }

  static WidgetStateProperty<BorderSide?> _side(
    Color color, {
    required double width,
    required bool dimWhenDisabled,
  }) {
    return WidgetStateProperty.resolveWith((states) {
      final disabled = states.contains(WidgetState.disabled);
      return BorderSide(
        color: disabled && dimWhenDisabled ? _dim(color) : color,
        width: width,
      );
    });
  }

  static Color _dim(Color color) {
    if (color.a == 0) return color;
    return color.withValues(alpha: color.a * disabledOpacity);
  }

  static Color _step(Color base, double lightness) {
    return HSLColor.fromColor(
      base,
    ).withLightness((lightness / 100).clamp(0.0, 1.0)).toColor();
  }
}
