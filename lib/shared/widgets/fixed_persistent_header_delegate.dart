import 'package:flutter/material.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

// Fixed Sized Persistent header Delegate
class FixedPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color? bgColor;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final double elevation;

  FixedPersistentHeaderDelegate({
    required this.child,
    this.height = 70.0,
    this.bgColor,
    this.padding = const .symmetric(horizontal: 16.0, vertical: 12.0),
    this.borderRadius,
    this.elevation = 0.0,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: bgColor ?? context.theme.scaffoldBackgroundColor,
      borderRadius: borderRadius,
      elevation: elevation,
      child: Container(
        height: maxExtent,
        width: double.maxFinite,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: bgColor ?? context.theme.scaffoldBackgroundColor,
        ),
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
