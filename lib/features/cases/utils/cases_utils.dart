import 'package:flutter_template/features/home/data/home_models.dart';

const _statusLabels = {
  RequestStatus.newRequest: 'New',
  RequestStatus.inReview: 'In Review',
  RequestStatus.actionNeeded: 'Action Needed',
  RequestStatus.resolved: 'Resolved',
};

String casesStatusLabel(RequestStatus status) => _statusLabels[status]!;

/// Parity with vcareapp `formatWhen` in requests/utils.ts.
String formatCasesWhen(DateTime date) {
  final diff = DateTime.now().difference(date);
  const day = Duration(days: 1);
  if (diff < day) return 'Today';
  if (diff < day * 2) return 'Yesterday';
  if (diff < day * 7) return '${diff.inDays}d ago';
  return '${date.month}/${date.day}/${date.year}';
}

/// Parity with `#{r.id.slice(-6).toUpperCase()}` in RequestsBody.
String formatRequestRef(String id) {
  final slice = id.length > 6 ? id.substring(id.length - 6) : id;
  return '#${slice.toUpperCase()}';
}
