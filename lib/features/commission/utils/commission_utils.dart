import 'package:intl/intl.dart';

import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/features/home/utils/home_stats_utils.dart';

const _agencySaleTitles = [
  'Membership Plan - Individual',
  'Membership Plan - Family',
  'Company Group - Monthly',
  'Membership Plan - Individual',
  'Company Group - Annual',
  'Membership Plan - Family',
  'Membership Plan - Individual',
];

String commissionStatusLabel(CommissionStatus status) => switch (status) {
      CommissionStatus.paid => 'Paid',
      CommissionStatus.pending => 'Earned',
      CommissionStatus.cancelled => 'Failed',
      CommissionStatus.unknown => 'Unknown',
    };

List<CommissionHistoryItem> filterCommissionHistory(
  List<CommissionHistoryItem> items,
  CommissionFilter filter,
) {
  if (filter == CommissionFilter.all) return items;

  return items.where((item) {
    return switch (filter) {
      CommissionFilter.paid => item.status == CommissionStatus.paid,
      CommissionFilter.earned => item.status == CommissionStatus.pending,
      CommissionFilter.failed => item.status == CommissionStatus.cancelled,
      CommissionFilter.all => true,
    };
  }).toList();
}

String formatCommissionMoney(String? amount, {bool signed = false}) {
  if (amount == null) return '—';

  final parsed = double.tryParse(amount);
  if (parsed == null) return '—';

  final formatted = NumberFormat.simpleCurrency(decimalDigits: 2).format(parsed.abs());
  if (!signed) return formatted;

  if (parsed > 0) return '+$formatted';
  if (parsed < 0) return '-$formatted';
  return formatted;
}

String agencySaleTitle(String id) {
  var hash = 0;
  for (var i = 0; i < id.length; i++) {
    hash = (hash * 31 + id.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return _agencySaleTitles[hash % _agencySaleTitles.length];
}

double agencySaleAmount(String commissionAmount) {
  final parsed = double.tryParse(commissionAmount) ?? 0;
  return (parsed.abs() * 10).clamp(99, double.infinity);
}

String commissionRateLabel(CommissionHistoryItem item) {
  final type = item.commissionType.toUpperCase();
  if (type == 'PERCENTAGE') {
    return '${item.commissionValue}% commission';
  }
  return item.commissionValue;
}

bool isCommissionSummaryEmpty({
  required String? totalSales,
  required bool historyEmpty,
}) {
  if (!historyEmpty) return false;

  final sales = double.tryParse(totalSales ?? '');
  return sales == null || sales == 0;
}
