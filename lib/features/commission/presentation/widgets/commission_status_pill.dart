import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_spacing.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';

/// Compact status pill: colored dot + label (web-style badge).
class CommissionStatusPill extends StatelessWidget {
  const CommissionStatusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VCareStatusColors.of(context, _toneFor(label));

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VCareSpacing.s2,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: VCareRadius.fullAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
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
                color: colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static VCareStatusTone _toneFor(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'failed' || normalized == 'rejected') {
      return VCareStatusTone.danger;
    }

    if (normalized == 'earned' ||
        normalized == 'paid' ||
        normalized == 'completed' ||
        normalized == 'successful') {
      return VCareStatusTone.success;
    }

    if (normalized == 'upcoming' || normalized == 'pending') {
      return VCareStatusTone.warning;
    }

    return VCareStatusTone.neutral;
  }
}
