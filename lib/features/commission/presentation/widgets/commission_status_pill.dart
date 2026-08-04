import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Compact status pill: colored dot + label (web-style badge).
class CommissionStatusPill extends StatelessWidget {
  const CommissionStatusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _style(label, context.vcare);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color bg, Color fg) _style(String status, VCareThemeExtension vcare) {
    final normalized = status.toLowerCase();

    if (normalized == 'failed' || normalized == 'rejected') {
      return (
        VCareColors.destructive.withValues(alpha: 0.12),
        VCareColors.destructive,
      );
    }

    if (normalized == 'earned' ||
        normalized == 'paid' ||
        normalized == 'completed' ||
        normalized == 'successful') {
      return (VCareColors.success.withValues(alpha: 0.14), VCareColors.success);
    }

    if (normalized == 'upcoming' || normalized == 'pending') {
      const orange = Color(0xFFC2410C);
      return (const Color(0x1AF97316), orange);
    }

    return (vcare.muted, vcare.mutedForeground);
  }
}
