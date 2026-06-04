import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';

/// Shared layout metrics for [VcarePageHeader] and pinned tab headers.
abstract final class VcarePageHeaderLayout {
  static const double horizontalPadding = 20;
  static const double topPadding = 16;
  static const double bottomPadding = 12;
  static const double titleFontSize = 24;
  static const double titleLineHeight = 1.2;
  static const double subtitleGap = 4;
  static const double subtitleFontSize = 14;
  static const double subtitleLineHeight = 1.25;

  static double contentHeight({required bool hasSubtitle}) {
    final titleBlock =
        topPadding + bottomPadding + titleFontSize * titleLineHeight;
    if (!hasSubtitle) return titleBlock;
    return titleBlock + subtitleGap + subtitleFontSize * subtitleLineHeight;
  }
}

/// Standard page header matching vcareapp [PageHeader] (non-welcome variant).
class VcarePageHeader extends StatelessWidget {
  const VcarePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.showBell = false,
    this.unreadCount = 0,
    this.onBellTap,
    this.action,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showBell;
  final int unreadCount;
  final VoidCallback? onBellTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VcarePageHeaderLayout.horizontalPadding,
        VcarePageHeaderLayout.topPadding,
        VcarePageHeaderLayout.horizontalPadding,
        VcarePageHeaderLayout.bottomPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: const Icon(LucideIcons.arrowLeft, size: 20),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: VcarePageHeaderLayout.titleFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: VcarePageHeaderLayout.titleLineHeight,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: VcarePageHeaderLayout.subtitleGap),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: VcarePageHeaderLayout.subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      height: VcarePageHeaderLayout.subtitleLineHeight,
                      color: vcare.mutedForeground.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
          if (showBell)
            IconButton(
              onPressed: onBellTap,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(LucideIcons.bell, size: 24),
                  if (unreadCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: VCareColors.destructive,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: VCareColors.background,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
