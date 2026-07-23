import 'package:intl/intl.dart';

import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_transaction_status.dart';

/// Badge label derived from API `status` (`PENDING` / `PAID` / `REJECTED`).
String commissionStatusLabel(CommissionStatus status) => switch (status) {
  CommissionStatus.pending => 'Pending',
  CommissionStatus.paid => 'Paid',
  CommissionStatus.cancelled => 'Rejected',
  CommissionStatus.unknown => 'Unknown',
};

/// Badge label for sales-history transaction status.
String salesTransactionStatusLabel(SalesTransactionStatus status) =>
    switch (status) {
      SalesTransactionStatus.pending => 'Pending',
      SalesTransactionStatus.paid => 'Paid',
      SalesTransactionStatus.failed => 'Failed',
      SalesTransactionStatus.refunded => 'Refunded',
      SalesTransactionStatus.voided => 'Voided',
      SalesTransactionStatus.unknown => 'Unknown',
    };

String formatCommissionMoney(double? amount, {bool signed = false}) {
  if (amount == null) return '—';

  final formatted = NumberFormat.simpleCurrency(
    decimalDigits: 2,
  ).format(amount.abs());
  if (!signed) return formatted;

  if (amount > 0) return '+$formatted';
  if (amount < 0) return '-$formatted';
  return formatted;
}

String commissionRateLabel(CommissionHistoryItem item) {
  final value = item.commissionValue?.trim();
  if (value == null || value.isEmpty) return '—';

  final type = item.commissionType.toUpperCase();
  if (type == 'PERCENTAGE') {
    return '$value% commission';
  }
  return value;
}

bool isCommissionSummaryEmpty({
  required double? totalSales,
  required bool historyEmpty,
}) {
  if (!historyEmpty) return false;
  return totalSales == null || totalSales == 0;
}
