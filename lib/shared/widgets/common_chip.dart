import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/common_icon.dart';

class CommonChip extends StatelessWidget {
  const CommonChip({
    super.key,
    required this.label,
    this.labelStyle,
    this.leading,
    this.trailing,
    this.padding,
    this.margin = .zero,
    this.borderRadius,
    this.border,
    this.width,
    this.height = 36.0,
    this.background,
    this.leadingColor,
    this.trailingColor,
    this.elevation = 0.0,
    this.shadowColor,
    this.onTap,
  });

  final String label;
  final TextStyle? labelStyle;

  /// [leading] can accept IconData or url or assetsImage
  ///
  final dynamic leading;

  /// [trailing] can accept IconData or url or assetsImage
  ///
  final dynamic trailing;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final double? width;
  final double height;
  final Color? background;
  final Color? leadingColor;
  final Color? trailingColor;
  final double elevation;
  final Color? shadowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(36.0);
    final onPrimary = context.theme.colorScheme.onPrimary;

    return Padding(
      padding: margin,
      child: Material(
        borderRadius: borderRadius ?? radius,
        elevation: elevation,
        shadowColor: shadowColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? radius,
          child: Ink(
            width: width,
            height: height,
            padding: padding ?? const .symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? radius,
              color: background ?? context.theme.primaryColor,
              border: border,
            ),
            child: Row(
              mainAxisAlignment: .center,
              crossAxisAlignment: .center,
              spacing: 8.0,
              mainAxisSize: .min,
              children: [
                if (leading != null &&
                    (leading is IconData || leading is String))
                  CommonIcon(
                    icon: leading,
                    color: leadingColor ?? onPrimary,
                    size: (16.0 / 36.0) * height,
                  ),
                Flexible(
                  child: Text(
                    label,
                    style: labelStyle ?? context.textTheme.regular14,
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                ),
                if (trailing != null &&
                    (trailing is IconData || trailing is String))
                  CommonIcon(
                    icon: trailing,
                    color: trailingColor ?? onPrimary,
                    size: (16.0 / 36.0) * height,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
