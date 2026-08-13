import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

enum AdminDashboardStatCardTone { primary, secondary, success, warning, danger }

enum AdminDashboardStatCaptionTone { positive, negative, neutral }

/// Compact stat card — fixed height, smaller type, tone-tinted surface.
class AdminDashboardStatCard extends StatelessWidget {
  const AdminDashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    this.caption,
    this.captionTone = AdminDashboardStatCaptionTone.neutral,
    required this.icon,
    this.iconTone = AdminDashboardStatCardTone.primary,
    this.empty = false,
    this.emptyCaption,
    this.onTap,
  });

  static const double cardHeight = 92;

  final String title;
  final String value;
  final String? caption;
  final AdminDashboardStatCaptionTone captionTone;
  final IconData icon;
  final AdminDashboardStatCardTone iconTone;
  final bool empty;
  final String? emptyCaption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final displayCaption = empty ? (emptyCaption ?? caption) : caption;

    return SizedBox(
      height: cardHeight,
      width: double.infinity,
      child: Material(
        color: empty
            ? vcare.muted.withValues(alpha: 0.22)
            : _surfaceColor(vcare, iconTone),
        borderRadius: VCareRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: VCareRadius.lgAll,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: VCareRadius.lgAll,
              border: Border.all(
                color: empty ? vcare.border : _borderColor(vcare, iconTone),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.1,
                      color: empty
                          ? vcare.mutedForeground.withValues(alpha: 0.85)
                          : vcare.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                value,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  letterSpacing: -0.3,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: empty
                                      ? vcare.mutedForeground
                                      : vcare.foreground,
                                ),
                              ),
                            ),
                            if (displayCaption case final caption?)
                              Text(
                                caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                  color: _captionColor(vcare, empty),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: empty
                              ? vcare.muted
                              : _iconBackground(vcare, iconTone),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          size: 14,
                          color: empty
                              ? vcare.mutedForeground
                              : _iconForeground(vcare, iconTone),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _surfaceColor(
    VCareThemeExtension vcare,
    AdminDashboardStatCardTone tone,
  ) {
    switch (tone) {
      case AdminDashboardStatCardTone.primary:
        return vcare.primary.withValues(alpha: 0.04);
      case AdminDashboardStatCardTone.secondary:
        return vcare.secondaryScale.s50.withValues(alpha: 0.45);
      case AdminDashboardStatCardTone.success:
        return vcare.successScale.s50.withValues(alpha: 0.55);
      case AdminDashboardStatCardTone.warning:
        return vcare.warningScale.s50.withValues(alpha: 0.55);
      case AdminDashboardStatCardTone.danger:
        return vcare.dangerScale.s50.withValues(alpha: 0.55);
    }
  }

  Color _borderColor(
    VCareThemeExtension vcare,
    AdminDashboardStatCardTone tone,
  ) {
    switch (tone) {
      case AdminDashboardStatCardTone.primary:
        return vcare.primary.withValues(alpha: 0.12);
      case AdminDashboardStatCardTone.secondary:
        return vcare.secondaryScale.s100.withValues(alpha: 0.7);
      case AdminDashboardStatCardTone.success:
        return vcare.successScale.s100.withValues(alpha: 0.7);
      case AdminDashboardStatCardTone.warning:
        return vcare.warningScale.s100.withValues(alpha: 0.7);
      case AdminDashboardStatCardTone.danger:
        return vcare.dangerScale.s100.withValues(alpha: 0.7);
    }
  }

  Color _captionColor(VCareThemeExtension vcare, bool isEmpty) {
    if (isEmpty) return vcare.mutedForeground;
    switch (captionTone) {
      case AdminDashboardStatCaptionTone.positive:
        return vcare.successScale.s600;
      case AdminDashboardStatCaptionTone.negative:
        return vcare.dangerScale.s500;
      case AdminDashboardStatCaptionTone.neutral:
        return vcare.mutedForeground;
    }
  }

  Color _iconBackground(
    VCareThemeExtension vcare,
    AdminDashboardStatCardTone tone,
  ) {
    switch (tone) {
      case AdminDashboardStatCardTone.primary:
        return vcare.primary.withValues(alpha: 0.12);
      case AdminDashboardStatCardTone.secondary:
        return vcare.secondary;
      case AdminDashboardStatCardTone.success:
        return vcare.successScale.s100;
      case AdminDashboardStatCardTone.warning:
        return vcare.warningScale.s100;
      case AdminDashboardStatCardTone.danger:
        return vcare.dangerScale.s100;
    }
  }

  Color _iconForeground(
    VCareThemeExtension vcare,
    AdminDashboardStatCardTone tone,
  ) {
    switch (tone) {
      case AdminDashboardStatCardTone.primary:
        return vcare.primary;
      case AdminDashboardStatCardTone.secondary:
        return VCareColors.secondaryForeground;
      case AdminDashboardStatCardTone.success:
        return vcare.successScale.s600;
      case AdminDashboardStatCardTone.warning:
        return vcare.warningScale.s700;
      case AdminDashboardStatCardTone.danger:
        return vcare.dangerScale.s500;
    }
  }
}
