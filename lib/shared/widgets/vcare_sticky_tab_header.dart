import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

/// Pinned page title that stays below the status bar — parity with web
/// [PageHeader] `safe-top sticky top-0`.
class VcarePinnedPageTitleDelegate extends SliverPersistentHeaderDelegate {
  VcarePinnedPageTitleDelegate({
    required this.safeTop,
    required this.title,
    this.hasSubtitle = true,
    this.showBottomBorder = false,
    this.textScaleFactor = 1.0,
  });

  final double safeTop;
  final Widget title;
  final bool hasSubtitle;
  final bool showBottomBorder;
  final double textScaleFactor;

  double get _contentHeight => VcarePageHeaderLayout.contentHeight(
    hasSubtitle: hasSubtitle,
    textScaleFactor: textScaleFactor,
  );

  @override
  double get minExtent => safeTop + _contentHeight;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final background = Theme.of(context).scaffoldBackgroundColor;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.95),
            border: showBottomBorder && overlapsContent
                ? Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.6),
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: safeTop),
              SizedBox(
                height: _contentHeight,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant VcarePinnedPageTitleDelegate oldDelegate) {
    return safeTop != oldDelegate.safeTop ||
        title != oldDelegate.title ||
        hasSubtitle != oldDelegate.hasSubtitle ||
        showBottomBorder != oldDelegate.showBottomBorder ||
        textScaleFactor != oldDelegate.textScaleFactor;
  }
}

/// Convenience builder for standard [VcarePageHeader] tab titles.
Widget vcareTabPageTitle({
  required String title,
  String? subtitle,
  Widget? action,
  bool showBack = false,
  VoidCallback? onBack,
}) {
  return VcarePageHeader(
    title: title,
    subtitle: subtitle,
    action: action,
    showBack: showBack,
    onBack: onBack,
  );
}
