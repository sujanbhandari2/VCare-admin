import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Matches vcareapp [ChatDateSeparator].
class AvaDateChip extends StatelessWidget {
  const AvaDateChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: vcare.muted.withValues(alpha: 0.6),
            borderRadius: VCareRadius.fullAll,
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: vcare.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
