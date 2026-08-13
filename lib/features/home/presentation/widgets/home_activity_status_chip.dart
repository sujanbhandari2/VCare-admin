import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_spacing.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';

/// Status chip colors aligned with vcareapp `HomeActivityRow.statusChipClass`.
class HomeActivityStatusChip extends StatelessWidget {
  const HomeActivityStatusChip({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;

  /// Web `Badge` with `text-[10px]` in RequestDetailsSheet (smaller than list chips).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = VCareStatusColors.of(context, _toneFor(label));

    return Container(
      height: compact ? null : 20,
      padding: EdgeInsets.symmetric(
        horizontal: VCareSpacing.s2,
        vertical: compact ? VCareSpacing.s0_5 : 0,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: VCareRadius.fullAll,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
          height: compact ? 1.1 : 1,
        ),
      ),
    );
  }

  static VCareStatusTone _toneFor(String status) {
    final normalized = status.toLowerCase();

    // Payment-failure short labels from `getFailedPaymentCopy` (+ banner chips).
    final isPaymentFailureChip =
        normalized == 'failed' ||
        normalized == 'overdue' ||
        normalized == 'payment failed' ||
        normalized == 'not enough funds' ||
        normalized == 'card problem' ||
        normalized == 'card declined' ||
        normalized.startsWith('payment failed ·') ||
        normalized.startsWith('not enough funds ·') ||
        normalized.startsWith('card problem ·') ||
        normalized.startsWith('card declined ·');

    if (isPaymentFailureChip) {
      return VCareStatusTone.danger;
    }

    if (normalized == 'paid' ||
        normalized == 'resolved' ||
        normalized == 'completed' ||
        normalized == 'done') {
      return VCareStatusTone.success;
    }

    if (normalized == 'new') {
      return VCareStatusTone.info;
    }

    // Web W-9 / agreement todos use orange for "Action needed".
    if (normalized == 'action needed') {
      return VCareStatusTone.warning;
    }

    if (normalized == 'in review' ||
        normalized == 'pending' ||
        normalized == 'due soon') {
      return VCareStatusTone.warning;
    }

    return VCareStatusTone.neutral;
  }
}
