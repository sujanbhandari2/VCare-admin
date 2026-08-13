/// Parses decimal-string amounts (`"120.00"`) returned by the enrollment API.
double parseMembershipAmount(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? 0;
}

/// Parses `yyyy-MM-dd` (as a local calendar day) or a full ISO timestamp.
///
/// Date-only values are kept local so a benefit date never shifts a day when
/// the device sits behind UTC — parity with web `parseApproveDate`.
DateTime? parseMembershipDate(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final datePart = trimmed.length >= 10 ? trimmed.substring(0, 10) : trimmed;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(datePart)) {
    final parts = datePart.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  final parsed = DateTime.tryParse(trimmed);
  return parsed?.toLocal();
}

/// `yyyy-MM-dd` request format for approve/compute and approve.
String formatMembershipApiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
