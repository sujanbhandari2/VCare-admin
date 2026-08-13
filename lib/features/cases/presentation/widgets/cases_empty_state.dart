import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Empty cases list — parity with [ClientsEmptyState].
class CasesEmptyState extends StatelessWidget {
  const CasesEmptyState({
    super.key,
    this.title = 'No cases found',
    this.description =
        'Try adjusting filters or search by client, case number, or type.',
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xxlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: vcare.primary.withValues(alpha: 0.1),
                borderRadius: VCareRadius.xlAll,
              ),
              child: Icon(
                LucideIcons.briefcase,
                color: vcare.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: vcare.mutedForeground,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
