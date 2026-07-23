import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

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
    final (bg, fg, border) = _style(label, context.vcare);

    return Container(
      height: compact ? null : 20,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 8,
        vertical: compact ? 2 : 0,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          height: compact ? 1.1 : 1,
        ),
      ),
    );
  }

  (Color bg, Color fg, Color border) _style(
    String status,
    VCareThemeExtension vcare,
  ) {
    final normalized = status.toLowerCase();

    if (normalized == 'failed' || normalized == 'overdue') {
      return (
        VCareColors.destructive.withValues(alpha: 0.1),
        VCareColors.destructive,
        VCareColors.destructive.withValues(alpha: 0.5),
      );
    }

    if (normalized == 'paid' ||
        normalized == 'resolved' ||
        normalized == 'completed' ||
        normalized == 'done') {
      const emerald = Color(0xFF047857);
      return (const Color(0x1A10B981), emerald, const Color(0x8010B981));
    }

    if (normalized == 'new') {
      const sky = Color(0xFF0369A1);
      return (const Color(0x1A0EA5E9), sky, const Color(0x800EA5E9));
    }

    // Web W-9 / agreement todos use orange-600 for "Action needed".
    if (normalized == 'action needed') {
      const orange = Color(0xFFEA580C);
      return (const Color(0x0DF97316), orange, const Color(0x66F97316));
    }

    if (normalized == 'in review' ||
        normalized == 'pending' ||
        normalized == 'due soon') {
      const amber = Color(0xFFB45309);
      return (const Color(0x1AF59E0B), amber, const Color(0x80F59E0B));
    }

    return (
      vcare.muted,
      vcare.mutedForeground,
      VCareColors.foreground.withValues(alpha: 0.25),
    );
  }
}
