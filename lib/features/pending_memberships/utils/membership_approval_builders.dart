import 'package:vcare_admin/features/pending_memberships/domain/entities/membership_approval.dart';
import 'package:vcare_admin/features/pending_memberships/utils/membership_parsers.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_formatters.dart';

/// Missed billing periods as selectable start dates, with "Today" last —
/// parity with web `mapMissedBillingStartOptions`.
List<MembershipBillingStartOption> buildBillingStartOptions(
  List<MembershipBillingPeriod> missedPeriods, {
  DateTime? now,
}) {
  final today = _startOfDay(now ?? DateTime.now());
  final todayValue = formatMembershipApiDate(today);

  final seen = <String>{};
  final options = <MembershipBillingStartOption>[];

  for (final period in missedPeriods) {
    final date = period.startDate;
    if (date == null) continue;

    final value = formatMembershipApiDate(date);
    if (value == todayValue || !seen.add(value)) continue;

    options.add(
      MembershipBillingStartOption(
        value: value,
        label: formatMembershipDate(date),
        date: date,
      ),
    );
  }

  options.sort((a, b) => a.value.compareTo(b.value));

  return [
    ...options,
    MembershipBillingStartOption(
      value: todayValue,
      label: 'Today',
      date: today,
      isToday: true,
    ),
  ];
}

/// Flattens the price list into display rows, keeping periods that priced to a
/// total but carry no line items — parity with web `buildApprovalTableRows`.
List<MembershipApprovalRow> buildApprovalRows(
  MembershipApprovalCompute compute,
) {
  final rows = <MembershipApprovalRow>[];

  for (var index = 0; index < compute.priceList.length; index += 1) {
    final entry = compute.priceList[index];
    final missedPeriod = index < compute.missedBillingPeriods.length
        ? compute.missedBillingPeriods[index]
        : null;
    final firstItem = entry.lineItems.isEmpty ? null : entry.lineItems.first;

    final periodStart = missedPeriod?.startDate ?? firstItem?.billingStartDate;
    final periodEnd = missedPeriod?.endDate ?? firstItem?.billingEndDate;

    if (entry.lineItems.isEmpty) {
      rows.add(
        MembershipApprovalRow(
          periodTotal: entry.totalAmount,
          payPeriodStart: periodStart,
          payPeriodEnd: periodEnd,
        ),
      );
      continue;
    }

    for (final item in entry.lineItems) {
      rows.add(
        MembershipApprovalRow(
          item: item,
          payPeriodStart: item.billingStartDate ?? periodStart,
          payPeriodEnd: item.billingEndDate ?? periodEnd,
        ),
      );
    }
  }

  return rows;
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);
