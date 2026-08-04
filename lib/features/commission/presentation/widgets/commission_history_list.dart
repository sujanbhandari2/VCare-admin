import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_history_item.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_detail_sheet.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_earnings_columns.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_history_row.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_sales_history_row.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_transaction_detail_sheet.dart';

/// Compact earnings list for mobile individual / agency modes.
///
/// parity: vcare-agent-app-2.0/src/features/commission/components/CommissionHistoryList.tsx
class CommissionHistoryList extends StatelessWidget {
  const CommissionHistoryList.commission({
    super.key,
    required List<CommissionHistoryItem> items,
  }) : _commissionItems = items,
       _salesItems = null,
       isAgencyTied = false;

  const CommissionHistoryList.sales({
    super.key,
    required List<SalesHistoryItem> items,
  }) : _salesItems = items,
       _commissionItems = null,
       isAgencyTied = true;

  final List<CommissionHistoryItem>? _commissionItems;
  final List<SalesHistoryItem>? _salesItems;
  final bool isAgencyTied;

  Future<void> _onCommissionTap(
    BuildContext context,
    CommissionHistoryItem item,
  ) async {
    if (item.canRecoverPayment) {
      final details = TodoPaymentFailedDetails(
        transactionId: item.transactionId!.trim(),
        payerId: item.clientId.trim(),
        payerName: item.displayClientName,
        amount: item.salesAmount ?? item.commissionAmount ?? 0,
        currency: 'USD',
        failureReason: null,
      );
      final synthetic = TodoItem(
        id: 'commission-failed:${item.id}',
        type: TodoType.paymentFailed,
        title: 'Payment failed',
        description: item.offeringName?.trim().isNotEmpty == true
            ? item.offeringName!.trim()
            : 'Failed payment recovery',
        occurredAt: DateTime.tryParse(item.displayDate) ?? DateTime.now(),
        paymentFailedDetails: details,
      );
      await TodoTransactionDetailSheet.show(context, item: synthetic);
      return;
    }

    await showCommissionDetailSheet(
      context,
      CommissionDetailViewData.fromHistory(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final showCommission = !isAgencyTied;
    final commissionItems = _commissionItems;
    final salesItems = _salesItems;
    final rowCount = commissionItems?.length ?? salesItems?.length ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(showCommission: showCommission),
          Divider(height: 1, thickness: 1, color: vcare.border),
          for (var i = 0; i < rowCount; i++) ...[
            if (commissionItems != null)
              CommissionHistoryRow(
                item: commissionItems[i],
                onTap: () => _onCommissionTap(context, commissionItems[i]),
              )
            else if (salesItems != null)
              CommissionSalesHistoryRow(
                item: salesItems[i],
                onTap: () => showCommissionDetailSheet(
                  context,
                  CommissionDetailViewData.fromSale(salesItems[i]),
                ),
              ),
            if (i < rowCount - 1)
              Divider(height: 1, thickness: 1, color: vcare.border),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.showCommission});

  final bool showCommission;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: vcare.mutedForeground,
    );

    return Padding(
      padding: CommissionEarningsColumns.headerPadding,
      child: Row(
        children: [
          Expanded(child: Text('CLIENT', style: style)),
          if (showCommission) ...[
            const SizedBox(width: CommissionEarningsColumns.gap),
            CommissionAmountCell(
              width: CommissionEarningsColumns.saleWidth,
              child: Text('SALE', style: style, textAlign: TextAlign.right),
            ),
            const SizedBox(width: CommissionEarningsColumns.gap),
            CommissionAmountCell(
              width: CommissionEarningsColumns.commissionWidth,
              child: Text(
                'COMMISSION',
                style: style,
                textAlign: TextAlign.right,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ] else
            Text('SALE', style: style),
        ],
      ),
    );
  }
}
