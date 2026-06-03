import 'package:flutter/material.dart';

import '../../core/styles/app_theme.dart';
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
    this.iconSize = 18.0,
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
    double iconSize = 18.0,
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
    double iconSize = 18.0,
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
    double iconSize = 18.0,
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
    final defaultRadius = borderRadius ?? BorderRadius.circular(8.0);
    final isDisabled = onPressed == null;

    final color = isDisabled && !loading
        ? type != .elevated
              ? Colors.grey
              : (this.color ?? context.theme.colorScheme.primary)
        : (this.color ?? context.theme.colorScheme.primary);

    final onButtonColor = isDisabled && !loading
        ? Colors.grey
        : (this.onButtonColor ??
              (type == .elevated
                  ? context.theme.colorScheme.onPrimary
                  : context.theme.colorScheme.primary));

    return SizedBox(
      width: width,
      height: height ?? 48,
      child: _buildButton(
        context,
        color,
        onButtonColor,
        defaultRadius,
        loading ? null : onPressed,
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    Color color,
    Color onButtonColor,
    BorderRadius borderRadius,
    VoidCallback? onPressed,
  ) {
    final textStyle = context.textTheme.semibold14?.copyWith(
      color: onButtonColor,
      fontSize: fontSize,
    );

    return type == .elevated
        ? FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: loading ? color : null,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              padding: padding,
              textStyle: textStyle,
            ),
            icon: loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onButtonColor,
                    ),
                  )
                : icon != null
                ? Icon(icon, size: iconSize, color: onButtonColor)
                : null,
            label: Text(
              uppercase ? text.uppercase : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
            iconAlignment: iconAlignment,
          )
        : type == .outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              disabledForegroundColor: color,
              iconColor: onButtonColor,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              side: BorderSide(color: color, width: 1),
              padding: padding,
              textStyle: textStyle,
            ),
            icon: loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onButtonColor,
                    ),
                  )
                : icon != null
                ? Icon(icon, size: iconSize, color: onButtonColor)
                : null,
            label: Text(
              uppercase ? text.uppercase : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
            iconAlignment: iconAlignment,
          )
        : TextButton.icon(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: color,
              disabledForegroundColor: color,
              iconColor: onButtonColor,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              padding: padding,
              textStyle: textStyle,
            ),
            icon: loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onButtonColor,
                    ),
                  )
                : icon != null
                ? Icon(icon, size: iconSize, color: onButtonColor)
                : null,
            label: Text(
              uppercase ? text.uppercase : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
            iconAlignment: iconAlignment,
          );
  }
}

/// Enum
enum AppButtonType { elevated, text, outlined }
