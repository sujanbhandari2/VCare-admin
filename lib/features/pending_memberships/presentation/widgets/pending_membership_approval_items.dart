import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/membership_approval.dart';
import 'package:vcare_admin/features/pending_memberships/utils/membership_approval_builders.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_formatters.dart';

/// Charge breakdown for an approval — parity with web
/// `ApprovalMembershipsTable` (line items, total, recurring notice).
class PendingMembershipApprovalItems extends StatelessWidget {
  const PendingMembershipApprovalItems({
    super.key,
    required this.compute,
    this.dimmed = false,
  });

  final MembershipApprovalCompute compute;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final rows = buildApprovalRows(compute);
    final currency = compute.currency;
    final recurring = compute.recurringSummary;
    final multiplePeriods = compute.priceList.length > 1;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: dimmed ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in rows) ...[
            _ApprovalRowCard(row: row, currency: currency),
            const SizedBox(height: 8),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: vcare.muted.withValues(alpha: 0.5),
              borderRadius: VCareRadius.lgAll,
              border: Border.all(color: vcare.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      multiplePeriods ? 'Grand total' : 'Total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formatMembershipMoney(
                      compute.grandTotal,
                      currency: currency,
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (recurring != null) ...[
            const SizedBox(height: 10),
            _RecurringNotice(summary: recurring, currency: currency),
          ],
        ],
      ),
    );
  }
}

class _ApprovalRowCard extends StatelessWidget {
  const _ApprovalRowCard({required this.row, required this.currency});

  final MembershipApprovalRow row;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final item = row.item;
    final payPeriod = formatMembershipPayPeriod(
      row.payPeriodStart,
      row.payPeriodEnd,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.lgAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        item == null
                            ? 'Billing period'
                            : item.clientName.isEmpty
                            ? 'Client'
                            : item.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item?.clientEmail != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          item!.clientEmail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatMembershipMoney(
                    item?.totalAmount ?? row.periodTotal,
                    currency: currency,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: item == null ? vcare.mutedForeground : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (item != null) ...[
              const SizedBox(height: 6),
              Text(item.offeringName, style: const TextStyle(fontSize: 13)),
              if (item.enrolledAsLabel?.isNotEmpty == true)
                Text(
                  item.enrolledAsLabel!,
                  style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
                ),
              if (item.description != null)
                Text(
                  item.description!,
                  style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
                ),
              if (item.discountAmount > 0)
                Text(
                  'Discount: '
                  '${formatMembershipMoney(item.discountAmount, currency: currency)}',
                  style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
                ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.calendarRange,
                  size: 12,
                  color: vcare.mutedForeground,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    payPeriod,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: vcare.mutedForeground,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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

class _RecurringNotice extends StatelessWidget {
  const _RecurringNotice({required this.summary, required this.currency});

  final MembershipRecurringSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final schedule = formatMembershipRecurringSchedule(
      nextExecutionDate: summary.nextExecutionDate,
      billingInterval: summary.billingInterval,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.infoScale.s50,
        borderRadius: VCareRadius.lgAll,
        border: Border.all(color: vcare.infoScale.s200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.info, size: 15, color: vcare.infoScale.s600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'A recurring fee of '
                '${formatMembershipMoney(summary.totalAmount, currency: currency)} '
                'will be scheduled $schedule.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: vcare.infoScale.s700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
