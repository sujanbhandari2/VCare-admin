import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_chips.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_formatters.dart';

/// Primary membership card in the review sheet — parity with web
/// `PrimaryMembershipSummary` (plan, fee, benefit start, status).
class PendingMembershipSummaryCard extends StatelessWidget {
  const PendingMembershipSummaryCard({super.key, required this.membership});

  final PendingMembership membership;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final offering = membership.offering;
    final registrationFee = offering.registrationFee ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.lgAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offering.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      PendingMembershipRelationshipChip(membership: membership),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PendingMembershipStatusBadge(status: membership.status),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: vcare.border),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: formatMembershipFeeIntervalLabel(
                      offering.billingInterval,
                    ),
                    value: formatMembershipMoney(offering.fee),
                    suffix: registrationFee > 0
                        ? '+${formatMembershipMoney(registrationFee)} reg.'
                        : null,
                    caption: formatMembershipFeeCadenceLabel(offering),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Benefit starts',
                    value: formatMembershipDate(membership.benefitStartDate),
                    icon: LucideIcons.calendar,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.suffix,
    this.caption,
    this.icon,
  });

  final String label;
  final String value;
  final String? suffix;
  final String? caption;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: vcare.mutedForeground),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        if (suffix != null)
          Text(
            suffix!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
          ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
          ),
        ],
      ],
    );
  }
}
