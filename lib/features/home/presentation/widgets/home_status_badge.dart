import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';

class HomeStatusBadge extends StatelessWidget {
  const HomeStatusBadge({
    super.key,
    required this.label,
    required this.variant,
  });

  final String label;
  final StatusBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: VCareRadius.fullAll,
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.2,
        ),
      ),
    );
  }

  (Color bg, Color fg, Color? border) _colors(BuildContext context) {
    final vcare = context.vcare;
    switch (variant) {
      case StatusBadgeVariant.primary:
        return (
          vcare.primary.withValues(alpha: 0.1),
          vcare.primary,
          vcare.primary.withValues(alpha: 0.3),
        );
      case StatusBadgeVariant.secondary:
        return (
          vcare.muted,
          vcare.mutedForeground,
          vcare.border,
        );
      case StatusBadgeVariant.destructive:
        return (
          vcare.destructive.withValues(alpha: 0.1),
          vcare.destructive,
          vcare.destructive.withValues(alpha: 0.3),
        );
      case StatusBadgeVariant.outline:
        return (
          vcare.primary.withValues(alpha: 0.1),
          vcare.primary,
          vcare.primary.withValues(alpha: 0.3),
        );
    }
  }
}
