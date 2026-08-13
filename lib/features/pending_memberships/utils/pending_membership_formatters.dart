import 'package:intl/intl.dart';

import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/utils/membership_parsers.dart';

/// `MM/dd/yyyy` — parity with web `formatDate` / `formatApproveDate`.
final DateFormat _membershipDateFormat = DateFormat('MM/dd/yyyy');

const String membershipEmptyValue = '—';

String formatMembershipDate(DateTime? date) {
  if (date == null) return membershipEmptyValue;
  return _membershipDateFormat.format(date);
}

/// `MM/dd/yyyy` for a raw API date string such as a date of birth.
String formatMembershipDateString(String? value) =>
    formatMembershipDate(parseMembershipDate(value));

/// `(555) 123-4567` for 10-digit US numbers, otherwise the value as stored.
String formatMembershipPhone(String? phone) {
  final trimmed = phone?.trim();
  if (trimmed == null || trimmed.isEmpty) return membershipEmptyValue;

  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  final national = digits.length == 11 && digits.startsWith('1')
      ? digits.substring(1)
      : digits;

  if (national.length != 10) return trimmed;

  return '(${national.substring(0, 3)}) '
      '${national.substring(3, 6)}-${national.substring(6)}';
}

/// `MM/dd/yyyy - MM/dd/yyyy` — parity with web `formatApprovePayPeriod`.
String formatMembershipPayPeriod(DateTime? start, DateTime? end) {
  final startLabel = formatMembershipDate(start);
  final endLabel = formatMembershipDate(end);

  if (start != null && end != null) return '$startLabel - $endLabel';
  if (start != null) return startLabel;
  if (end != null) return endLabel;
  return membershipEmptyValue;
}

String formatMembershipMoney(double amount, {String currency = 'USD'}) {
  final fractionDigits = amount % 1 == 0 ? 0 : 2;
  try {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: _currencySymbol(currency),
      decimalDigits: fractionDigits,
    ).format(amount);
  } catch (_) {
    return '\$${amount.toStringAsFixed(fractionDigits)}';
  }
}

String _currencySymbol(String currency) {
  switch (currency.trim().toUpperCase()) {
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    default:
      return '\$';
  }
}

/// "Monthly fee" / "Quarterly fee" / "Annual fee" — parity with web
/// `formatMembershipFeeIntervalLabel`.
String formatMembershipFeeIntervalLabel(String? billingInterval) {
  switch (billingInterval?.trim().toUpperCase()) {
    case 'QUARTERLY':
      return 'Quarterly fee';
    case 'YEARLY':
      return 'Annual fee';
    default:
      return 'Monthly fee';
  }
}

/// "Per individual per month" — parity with web
/// `formatMembershipFeeCadenceLabel`.
String formatMembershipFeeCadenceLabel(MembershipOffering offering) {
  final offeringType = offering.offeringType?.trim().toUpperCase();
  final billingModel = offering.billingModel?.trim().toUpperCase();

  final audience = offeringType == 'FAMILY'
      ? 'family'
      : offeringType == 'GROUP' && billingModel == 'GROUP_FLAT_RATE'
      ? 'group'
      : 'individual';

  final interval = switch (offering.billingInterval?.trim().toUpperCase()) {
    'QUARTERLY' => 'quarter',
    'YEARLY' => 'year',
    _ => 'month',
  };

  return 'Per $audience per $interval';
}

/// Recurring schedule copy for the approval banner — parity with web
/// `formatRecurringScheduleLabel`.
String formatMembershipRecurringSchedule({
  DateTime? nextExecutionDate,
  String? billingInterval,
}) {
  if (nextExecutionDate != null) {
    return 'on ${formatMembershipDate(nextExecutionDate)}';
  }

  switch (billingInterval?.trim().toUpperCase()) {
    case 'MONTHLY':
      return 'every month';
    case 'QUARTERLY':
      return 'every quarter';
    case 'YEARLY':
      return 'every year';
    default:
      return 'on schedule';
  }
}

/// Relationship chip label — parity with web
/// `resolveMembershipRelationshipDisplay` (label only; tone is resolved in UI).
String? membershipRelationshipLabel(PendingMembership membership) {
  final label = membership.enrollmentDisplayLabel?.trim();
  if (label == null || label.isEmpty) return null;
  return label;
}

enum MembershipRelationshipTone { primary, group, dependent }

MembershipRelationshipTone membershipRelationshipTone(
  PendingMembership membership,
) {
  final label = membership.enrollmentDisplayLabel?.trim().toLowerCase() ?? '';

  if (label.startsWith('group') ||
      membership.offering.offeringType?.trim().toUpperCase() == 'GROUP') {
    return MembershipRelationshipTone.group;
  }
  if (label == 'primary') return MembershipRelationshipTone.primary;
  return MembershipRelationshipTone.dependent;
}
