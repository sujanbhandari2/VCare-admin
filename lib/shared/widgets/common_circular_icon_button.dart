import 'package:flutter/material.dart';

import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/common_icon.dart';

/// CommonCircularIconButton
///
class CommonCircularIconButton extends StatelessWidget {
  const CommonCircularIconButton({
    super.key,
    required this.icon,
    this.size = 48.0,
    this.iconSize,
    this.loading = false,
    this.hasBorder = true,
    this.elevation = 0.0,
    this.backgroundColor,
    this.iconColor,
    this.onClick,
  });

  /// [icon] might be IconData or icon assetsName or icon url
  /// e.g. Icons.add, or "assets/icons/my-icon.png", or "https://image.com/icon.png"
  ///
  final dynamic icon;
  final double size;
  final double? iconSize;
  final bool loading;
  final bool hasBorder;
  final double elevation;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onClick;

  @override
  Widget build(BuildContext context) {
    final iconSize = this.iconSize ?? (size / 2.25);
    return Material(
      borderRadius: .circular(50.0),
      elevation: elevation,
      shadowColor: context.theme.shadowColor.withValues(alpha: 0.25),
      color: backgroundColor,
      child: InkWell(
        onTap: !loading ? onClick : null,
        borderRadius: .circular(50.0),
        splashColor: context.theme.primaryColor.withValues(alpha: 0.5),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: .circular(size),
            border: hasBorder
                ? .all(width: 1.0, color: context.theme.colorScheme.outline)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: CommonIcon(icon: icon, size: iconSize, color: iconColor),
              ),
              if (loading)
                Center(
                  child: SizedBox(
                    width: double.maxFinite,
                    height: double.maxFinite,
                    child: CircularProgressIndicator(
                      color: context.theme.primaryColor,
                      strokeWidth: 1.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
