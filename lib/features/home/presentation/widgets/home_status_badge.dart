import 'package:flutter/material.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/features/home/data/home_models.dart';

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
        borderRadius: BorderRadius.circular(999),
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
    switch (variant) {
      case StatusBadgeVariant.primary:
        return (
          VCareColors.primary.withValues(alpha: 0.1),
          VCareColors.primary,
          VCareColors.primary.withValues(alpha: 0.3),
        );
      case StatusBadgeVariant.secondary:
        return (
          VCareColors.muted,
          VCareColors.mutedForeground,
          VCareColors.border,
        );
      case StatusBadgeVariant.destructive:
        return (
          VCareColors.destructive.withValues(alpha: 0.1),
          VCareColors.destructive,
          VCareColors.destructive.withValues(alpha: 0.3),
        );
      case StatusBadgeVariant.outline:
        return (
          VCareColors.primary.withValues(alpha: 0.1),
          VCareColors.primary,
          VCareColors.primary.withValues(alpha: 0.3),
        );
    }
  }
}
