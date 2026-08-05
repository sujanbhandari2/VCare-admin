import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Shared layout metrics for [VcarePageHeader] and pinned tab headers.
abstract final class VcarePageHeaderLayout {
  static const double horizontalPadding = 20;
  static const double topPadding = 16;
  static const double bottomPadding = 12;
  static const double itemGap = 12;
  static const double backButtonOffset = -8;
  static const double titleFontSize = 24;
  static const double titleLineHeight = 1.25;
  static const double subtitleGap = 2;
  static const double subtitleFontSize = 14;
  static const double subtitleLineHeight = 1.25;
  /// Extra space for font metric rounding and bold glyph ascent.
  static const double layoutBuffer = 2;

  static double _scaledLineHeight(double fontSize, double lineHeight, double scale) {
    return (fontSize * lineHeight * scale).ceilToDouble();
  }

  static double contentHeight({
    required bool hasSubtitle,
    double textScaleFactor = 1.0,
  }) {
    final scale = textScaleFactor < 1.0 ? 1.0 : textScaleFactor;
    final titleLine = _scaledLineHeight(titleFontSize, titleLineHeight, scale);
    final titleBlock = topPadding + bottomPadding + titleLine;
    if (!hasSubtitle) return titleBlock + layoutBuffer;
    final subtitleLine =
        _scaledLineHeight(subtitleFontSize, subtitleLineHeight, scale);
    return titleBlock + subtitleGap + subtitleLine + layoutBuffer;
  }

  static TextStyle titleTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          height: titleLineHeight,
        ) ??
        const TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          height: titleLineHeight,
        );
  }

  static TextStyle subtitleTextStyle(
    BuildContext context,
    Color mutedForeground,
  ) {
    return TextStyle(
      fontSize: subtitleFontSize,
      fontWeight: FontWeight.w400,
      height: subtitleLineHeight,
      color: mutedForeground,
    );
  }
}

/// Text-only header CTA — parity with vcareapp [HeaderActionButton].
class VcareHeaderActionButton extends StatelessWidget {
  const VcareHeaderActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: VCareColors.primary,
          disabledForegroundColor: VCareColors.primary.withValues(alpha: 0.45),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VCareColors.primary,
                ),
              )
            : Text(
                label,
                style: context.textTheme.semibold14?.copyWith(
                  color: onPressed == null
                      ? VCareColors.primary.withValues(alpha: 0.45)
                      : VCareColors.primary,
                ),
              ),
      ),
    );
  }
}

/// Sticky frosted page header — parity with web [PageHeader] `safe-top sticky`.
class VcareStickyPageHeader extends StatelessWidget {
  const VcareStickyPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.showBell = false,
    this.unreadCount = 0,
    this.onBellTap,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showBell;
  final int unreadCount;
  final VoidCallback? onBellTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final safeTop = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.95),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: safeTop),
            child: VcarePageHeader(
              title: title,
              subtitle: subtitle,
              leading: leading,
              showBack: showBack,
              onBack: onBack,
              showBell: showBell,
              unreadCount: unreadCount,
              onBellTap: onBellTap,
              action: action,
            ),
          ),
        ),
      ),
    );
  }
}

/// Scroll sliver with top safe-area inset before [VcarePageHeader].
class SliverVcarePageHeader extends StatelessWidget {
  const SliverVcarePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.showBell = false,
    this.unreadCount = 0,
    this.onBellTap,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showBell;
  final int unreadCount;
  final VoidCallback? onBellTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          VcarePageHeader(
            title: title,
            subtitle: subtitle,
            leading: leading,
            showBack: showBack,
            onBack: onBack,
            showBell: showBell,
            unreadCount: unreadCount,
            onBellTap: onBellTap,
            action: action,
          ),
        ],
      ),
    );
  }
}

/// Standard page header matching vcareapp [PageHeader] (non-welcome variant).
class VcarePageHeader extends StatelessWidget {
  const VcarePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.showBell = false,
    this.unreadCount = 0,
    this.onBellTap,
    this.action,
  });

  final String title;
  final String? subtitle;
  /// Optional widget shown before the title (e.g. conversation avatar).
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showBell;
  final int unreadCount;
  final VoidCallback? onBellTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final titleStyle = VcarePageHeaderLayout.titleTextStyle(context);
    final subtitleStyle = VcarePageHeaderLayout.subtitleTextStyle(
      context,
      vcare.mutedForeground,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VcarePageHeaderLayout.horizontalPadding,
        VcarePageHeaderLayout.topPadding,
        VcarePageHeaderLayout.horizontalPadding,
        VcarePageHeaderLayout.bottomPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack) ...[
            _VcarePageHeaderBackButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
            ),
            const SizedBox(width: VcarePageHeaderLayout.itemGap),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: VcarePageHeaderLayout.itemGap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                  strutStyle: StrutStyle.fromTextStyle(
                    titleStyle,
                    forceStrutHeight: true,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: VcarePageHeaderLayout.subtitleGap),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                    strutStyle: StrutStyle.fromTextStyle(
                      subtitleStyle,
                      forceStrutHeight: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: VcarePageHeaderLayout.itemGap),
            action!,
          ],
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

class _VcarePageHeaderBackButton extends StatelessWidget {
  const _VcarePageHeaderBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(VcarePageHeaderLayout.backButtonOffset, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              LucideIcons.arrowLeft,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
