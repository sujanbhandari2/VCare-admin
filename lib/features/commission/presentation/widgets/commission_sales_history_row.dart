import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_transaction_status.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_earnings_columns.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_status_pill.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';

/// Compact sales row: client + date, sale amount + status on the right.
class CommissionSalesHistoryRow extends StatelessWidget {
  const CommissionSalesHistoryRow({super.key, required this.item, this.onTap});

  final SalesHistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final statusLabel = salesTransactionStatusLabel(item.status);
    final isFailed = item.status == SalesTransactionStatus.failed;
    final amountColor = isFailed
        ? VCareColors.destructive
        : VCareColors.foreground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: CommissionEarningsColumns.rowPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayPayerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatClientDateNumeric(item.transactionDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCommissionMoney(item.amount, currency: item.currency),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                  if (isFailed) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Failed to collect',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: VCareColors.destructive,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  CommissionStatusPill(label: statusLabel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommissionSalesHistoryEmptyFilter extends StatelessWidget {
  const CommissionSalesHistoryEmptyFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border, style: BorderStyle.solid),
      ),
      child: Text(
        'No sales yet.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
      ),
    );
  }
}
