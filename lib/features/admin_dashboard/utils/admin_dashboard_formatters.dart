import 'package:intl/intl.dart';

/// Formats currency for admin dashboard stat cards and payment rows.
String formatAdminDashboardMoney(
  num amount, {
  String currency = 'USD',
}) {
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
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    default:
      return '\$';
  }
}

/// Calendar-day due label — parity with web `formatAdminTodoDueLabel`.
String formatAdminDashboardDueLabel(DateTime dueDate, [DateTime? now]) {
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(
    (now ?? DateTime.now()).year,
    (now ?? DateTime.now()).month,
    (now ?? DateTime.now()).day,
  );
  final diff = due.difference(today).inDays;

  if (diff < 0) {
    final days = diff.abs();
    return days == 1 ? '1d overdue' : '${days}d overdue';
  }
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  return 'in ${diff}d';
}

/// Preview limit for dashboard list widgets.
const adminDashboardWidgetPreviewLimit = 3;

/// Failed payments fetch limit for stat card aggregation.
const adminDashboardFailedPaymentsStatLimit = 100;
