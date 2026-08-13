// TODO: Re-enable when todo list API is available.
// import 'home_mock_data.dart';
import 'home_models.dart';

String formatWhen(DateTime iso) {
  final diff = DateTime.now().difference(iso);
  const hr = Duration(hours: 1);
  const day = Duration(days: 1);

  if (diff < hr) {
    final minutes = diff.inMinutes.clamp(1, 999999);
    return '${minutes}m ago';
  }
  if (diff < day) {
    return '${diff.inHours}h ago';
  }
  if (diff < const Duration(days: 7)) {
    return '${diff.inDays}d ago';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[iso.month - 1]} ${iso.day}';
}

List<ActivityItem> defaultRecentActivity() {
  // TODO: Re-enable when todo list API is available.
  return const [];
}

ActivityItem _failedTransaction() {
  final when = DateTime.now().subtract(const Duration(minutes: 30));
  return ActivityItem(
    kind: ActivityKind.transaction,
    id: 'txn-2',
    title: 'Dental Plus — Monthly premium',
    subtitle: 'Card declined · Visa •••• 4242',
    when: when,
    transaction: HomeTransaction(
      invoiceNumber: 'VC-2026-00191',
      membership: 'Dental Plus',
      amount: 41.99,
      currency: 'USD',
      status: 'Failed',
      paidAt: when,
      periodStart: when,
      periodEnd: when.add(const Duration(days: 30)),
      payerName: 'Alex Rivera',
      method: 'Visa •••• 4242',
      failureReason: 'Card declined',
    ),
  );
}

ActivityItem _paidTransaction() {
  final when = DateTime.now().subtract(const Duration(hours: 6));
  return ActivityItem(
    kind: ActivityKind.transaction,
    id: 'txn-1',
    title: 'VCare Family Plus — Monthly membership',
    subtitle: 'Paid · Visa •••• 4242',
    when: when,
    transaction: HomeTransaction(
      invoiceNumber: 'VC-2026-00184',
      membership: 'VCare Family Plus',
      amount: 129,
      currency: 'USD',
      status: 'Paid',
      paidAt: when,
      periodStart: when,
      periodEnd: when.add(const Duration(days: 30)),
      payerName: 'Alex Rivera',
      method: 'Visa •••• 4242',
    ),
  );
}

/// Kept for callers that still seed demo transaction activity.
List<ActivityItem> demoTransactionActivity() => [
  _failedTransaction(),
  _paidTransaction(),
];
