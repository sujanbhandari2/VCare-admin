import 'package:intl/intl.dart';

import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_transaction_status.dart';

/// Fallback badge label from mapped enum.
String commissionStatusLabel(CommissionStatus status) => switch (status) {
  CommissionStatus.pending => 'Pending',
  CommissionStatus.paid => 'Successful',
  CommissionStatus.cancelled => 'Rejected',
  CommissionStatus.failed => 'Failed',
  CommissionStatus.upcoming => 'Upcoming',
  CommissionStatus.unknown => 'Unknown',
};

/// Agent-facing status label for history rows (matches web).
///
/// parity: vcare-agent-app-2.0/src/features/commission/utils.ts
String resolveCommissionStatusLabel(CommissionHistoryItem item) {
  final s = item.apiStatus.toUpperCase();
  if (s == 'FAILED') return 'Failed';
  if (s == 'REJECTED') return 'Rejected';
  final itemType = item.itemType?.toUpperCase();
  if (s == 'UPCOMING' ||
      itemType == 'UPCOMING' ||
      itemType == 'ENROLLMENT' ||
      item.id.startsWith('pending:') ||
      item.id.startsWith('subscription:')) {
    return 'Upcoming';
  }
  if (s == 'PENDING') return 'Pending';
  if (s == 'PAID') return 'Successful';
  if (item.apiStatus.trim().isNotEmpty) return item.apiStatus;
  return commissionStatusLabel(item.status);
}

/// Badge label for sales-history transaction status.
String salesTransactionStatusLabel(SalesTransactionStatus status) =>
    switch (status) {
      SalesTransactionStatus.pending => 'Upcoming',
      SalesTransactionStatus.paid => 'Earned',
      SalesTransactionStatus.failed => 'Failed',
      SalesTransactionStatus.refunded => 'Refunded',
      SalesTransactionStatus.voided => 'Voided',
      SalesTransactionStatus.unknown => 'Unknown',
    };

String formatCommissionMoney(
  double? amount, {
  bool signed = false,
  String? currency,
}) {
  if (amount == null) return '—';

  final code = (currency ?? 'USD').trim().toUpperCase();
  final formatted = NumberFormat.simpleCurrency(
    name: code.isEmpty ? 'USD' : code,
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
  double? totalCommission,
  int upcomingCount = 0,
  int needsAttentionCount = 0,
  required bool historyEmpty,
}) {
  if (!historyEmpty) return false;
  if (upcomingCount > 0 || needsAttentionCount > 0) return false;
  final salesEmpty = totalSales == null || totalSales == 0;
  final commissionEmpty = totalCommission == null || totalCommission == 0;
  return salesEmpty && commissionEmpty;
}

/// Sum sale amounts for aggregate metrics (matches web `aggregateSaleTotals`).
({double total, int count}) aggregateSaleTotals(
  Iterable<CommissionHistoryItem> entries,
) {
  var total = 0.0;
  var count = 0;
  for (final entry in entries) {
    final sale = entry.salesAmount;
    if (sale == null) continue;
    total += sale;
    count += 1;
  }
  return (total: total, count: count);
}

/// Short transaction ref matching web detail drawer (`#` + last 4 hex).
String formatShortTransactionRef(String? id) {
  final compact = (id ?? '').replaceAll('-', '');
  if (compact.isEmpty) return '—';
  final tail = compact.length <= 4
      ? compact
      : compact.substring(compact.length - 4);
  return '#${tail.toUpperCase()}';
}
