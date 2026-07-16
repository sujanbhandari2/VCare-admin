import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';

class HomeEmptyStateCard extends StatelessWidget {
  const HomeEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.ctaLabel,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.borderRadius = 16,
  });

  final IconData icon;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: vcare.border,
          style: BorderStyle.solid,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          painter: VcareDashedBorderPainter(
            color: vcare.border,
            radius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                VcareEmptyStateCardContent(
                  icon: icon,
                  title: title,
                  description: description,
                  iconColor: iconColor,
                  iconBackgroundColor: iconBackgroundColor,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: VCareColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ctaLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VCareColors.primaryForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
