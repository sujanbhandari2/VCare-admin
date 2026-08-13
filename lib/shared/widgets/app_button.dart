import 'package:flutter/material.dart';

import '../../core/styles/app_theme.dart';
import '../../core/styles/vcare_button_styles.dart';
import '../../core/styles/vcare_theme.dart';
import '../utils/extension_functions.dart';

class AppButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final IconAlignment? iconAlignment;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? onButtonColor;
  final VoidCallback? onPressed;
  final double iconSize;
  final bool loading;
  final bool uppercase;
  final AppButtonType type;
  final double? fontSize;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppButton._({
    required this.text,
    this.icon,
    this.iconAlignment = .start,
    this.borderRadius,
    this.color,
    this.onButtonColor,
    this.onPressed,
    this.iconSize = VCareButtonStyles.iconSize,
    this.loading = false,
    this.uppercase = false,
    this.type = .elevated,
    this.fontSize,
    this.height,
    this.width,
    this.padding,
  });

  factory AppButton.elevated({
    required String text,
    IconData? icon,
    IconAlignment? iconAlignment,
    BorderRadius? borderRadius,
    Color? color,
    Color? onButtonColor,
    double iconSize = VCareButtonStyles.iconSize,
    bool loading = false,
    bool uppercase = false,
    double? fontSize,
    double? height,
    double? width = double.infinity,
    EdgeInsetsGeometry? padding,
    VoidCallback? onPressed,
  }) {
    return AppButton._(
      text: text,
      icon: icon,
      iconAlignment: iconAlignment,
      borderRadius: borderRadius,
      color: color,
      onButtonColor: onButtonColor,
      iconSize: iconSize,
      loading: loading,
      uppercase: uppercase,
      type: .elevated,
      fontSize: fontSize,
      height: height,
      width: width,
      padding: padding,
      onPressed: onPressed,
    );
  }

  factory AppButton.outlined({
    required String text,
    IconData? icon,
    IconAlignment? iconAlignment,
    BorderRadius? borderRadius,
    Color? color,
    Color? onButtonColor,
    double iconSize = VCareButtonStyles.iconSize,
    bool loading = false,
    bool uppercase = false,
    double? fontSize,
    double? height,
    double? width = double.infinity,
    EdgeInsetsGeometry? padding,
    VoidCallback? onPressed,
  }) {
    return AppButton._(
      text: text,
      icon: icon,
      iconAlignment: iconAlignment,
      borderRadius: borderRadius,
      color: color,
      onButtonColor: onButtonColor,
      iconSize: iconSize,
      loading: loading,
      uppercase: uppercase,
      type: .outlined,
      fontSize: fontSize,
      height: height,
      width: width,
      padding: padding,
      onPressed: onPressed,
    );
  }

  factory AppButton.text({
    required String text,
    IconData? icon,
    IconAlignment? iconAlignment,
    BorderRadius? borderRadius,
    Color? color,
    Color? onButtonColor,
    double iconSize = VCareButtonStyles.iconSize,
    bool loading = false,
    bool uppercase = false,
    double? fontSize,
    double? height,
    double? width = double.infinity,
    EdgeInsetsGeometry? padding,
    VoidCallback? onPressed,
  }) {
    return AppButton._(
      text: text,
      icon: icon,
      iconAlignment: iconAlignment,
      borderRadius: borderRadius,
      color: color,
      onButtonColor: onButtonColor,
      iconSize: iconSize,
      loading: loading,
      uppercase: uppercase,
      type: .text,
      fontSize: fontSize,
      height: height,
      width: width,
      padding: padding,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? VCareButtonSize.md.height,
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    final vcare = context.vcare;
    final labelStyle = context.textTheme.medium14;
    final spinnerColor = onButtonColor ?? _spinnerColor(context, vcare);

    final style = switch (type) {
      AppButtonType.elevated => VCareButtonStyles.filled(
        background: color ?? vcare.primary,
        foreground: onButtonColor ?? context.theme.colorScheme.onPrimary,
        size: VCareButtonSize.md,
        labelStyle: labelStyle,
        fontSize: fontSize,
        borderRadius: borderRadius,
        padding: padding,
        dimWhenDisabled: !loading,
      ),
      // A caller-supplied colour means an intentionally tinted outline; the
      // default is the neutral web `variant="outline"` used for Cancel/Back.
      AppButtonType.outlined when color != null =>
        VCareButtonStyles.outlinedTinted(
          color: onButtonColor ?? color!,
          size: VCareButtonSize.md,
          labelStyle: labelStyle,
          fontSize: fontSize,
          borderRadius: borderRadius,
          padding: padding,
          dimWhenDisabled: !loading,
        ),
      AppButtonType.outlined => VCareButtonStyles.outlined(
        foreground: onButtonColor ?? vcare.foreground,
        border: vcare.input,
        background: vcare.background,
        hoverBackground: vcare.accent,
        hoverForeground: vcare.accentForeground,
        size: VCareButtonSize.md,
        labelStyle: labelStyle,
        fontSize: fontSize,
        borderRadius: borderRadius,
        padding: padding,
        dimWhenDisabled: !loading,
      ),
      AppButtonType.text => VCareButtonStyles.ghost(
        foreground: onButtonColor ?? color ?? vcare.primary,
        hoverBackground: vcare.accent,
        size: VCareButtonSize.md,
        labelStyle: labelStyle,
        fontSize: fontSize,
        borderRadius: borderRadius,
        padding: padding,
        dimWhenDisabled: !loading,
      ),
    };

    final leading = loading
        ? SizedBox(
            width: VCareButtonStyles.iconSize,
            height: VCareButtonStyles.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : icon != null
        ? Icon(icon, size: iconSize)
        : null;

    final label = Text(
      uppercase ? text.uppercase : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final effectiveOnPressed = loading ? null : onPressed;

    return switch (type) {
      AppButtonType.elevated => FilledButton.icon(
        onPressed: effectiveOnPressed,
        style: style,
        icon: leading,
        label: label,
        iconAlignment: iconAlignment,
      ),
      AppButtonType.outlined => OutlinedButton.icon(
        onPressed: effectiveOnPressed,
        style: style,
        icon: leading,
        label: label,
        iconAlignment: iconAlignment,
      ),
      AppButtonType.text => TextButton.icon(
        onPressed: effectiveOnPressed,
        style: style,
        icon: leading,
        label: label,
        iconAlignment: iconAlignment,
      ),
    };
  }

  Color _spinnerColor(BuildContext context, VCareThemeExtension vcare) {
    return switch (type) {
      AppButtonType.elevated => context.theme.colorScheme.onPrimary,
      AppButtonType.outlined => color ?? vcare.foreground,
      AppButtonType.text => color ?? vcare.primary,
    };
  }
}

/// Enum
enum AppButtonType { elevated, text, outlined }
