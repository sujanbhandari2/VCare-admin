import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_formatters.dart';
import 'package:vcare_admin/features/home/data/home_activity_builder.dart';
import 'package:vcare_admin/features/todo/utils/failed_payment_copy.dart';

class AdminDashboardFailedPaymentRow extends StatelessWidget {
  const AdminDashboardFailedPaymentRow({
    super.key,
    required this.item,
    this.onTap,
  });

  final AdminDashboardFailedPaymentTodoItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final details = item.details;
    final payerName = details.name?.trim().isNotEmpty == true
        ? details.name!.trim()
        : 'Client';
    final failureCopy = getFailedPaymentCopy(
      details.failureReason,
      payerName,
      details.failureMessage,
    );
    final amount = double.tryParse(details.amount ?? '') ?? 0;
    final currency = details.currency?.trim().isNotEmpty == true
        ? details.currency!.trim()
        : 'USD';
    final amountLabel = formatAdminDashboardMoney(amount, currency: currency);
    final offeringName = details.membershipName?.trim();
    final relativeWhen = formatWhen(item.occurredAt);
    final showReasonChip =
        failureCopy.shortLabel.trim().toLowerCase() != 'payment failed';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.mdAll,
        child: Ink(
          decoration: BoxDecoration(
            color: vcare.dangerScale.s50,
            borderRadius: VCareRadius.mdAll,
            border: Border.all(color: vcare.dangerScale.s200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: vcare.dangerScale.s100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.alertTriangle,
                    size: 14,
                    color: vcare.dangerScale.s500,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (showReasonChip) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: vcare.card,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: vcare.dangerScale.s200,
                                      ),
                                    ),
                                    child: Text(
                                      failureCopy.shortLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: vcare.dangerScale.s600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            amountLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: vcare.dangerScale.s600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: vcare.primary,
                        ),
                      ),
                      if (offeringName != null || relativeWhen.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          [
                            ?offeringName,
                            if (relativeWhen.isNotEmpty) relativeWhen,
                          ].whereType<String>().join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: vcare.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
