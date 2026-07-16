import 'package:intl/intl.dart';

import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';

/// Parses profile DOB from ISO (`yyyy-MM-dd`, timestamps) or US (`MM/dd/yyyy`).
DateTime? parseProfileDob(String? input) {
  if (input == null || input.isEmpty) {
    return null;
  }
  final iso = DateTime.tryParse(input);
  if (iso != null) {
    return iso;
  }
  try {
    return DateFormat('MM/dd/yyyy').parseStrict(input);
  } on FormatException {
    return null;
  }
}

/// ISO date (`yyyy-MM-dd`) for profile edit inputs.
String profileDobToIso(String? input) {
  if (input == null || input.isEmpty) {
    return '';
  }
  final parsed = parseProfileDob(input);
  if (parsed == null) {
    return input;
  }
  final year = parsed.year.toString().padLeft(4, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// US date format MM/DD/YYYY — parity with vcareapp formatUsDate.
String formatProfileDob(String? input) {
  if (input == null || input.isEmpty) {
    return '';
  }
  final parsed = parseProfileDob(input);
  if (parsed == null) {
    return input;
  }
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');
  return '$month/$day/${parsed.year}';
}

String profileInitials(String name) {
  final parts = name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first[0].toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

int ageFromDob(String dob) {
  final parsed = parseProfileDob(dob);
  if (parsed == null) {
    return 0;
  }
  final now = DateTime.now();
  var age = now.year - parsed.year;
  if (now.month < parsed.month ||
      (now.month == parsed.month && now.day < parsed.day)) {
    age--;
  }
  return age < 0 ? 0 : age;
}

String formatProfileAddress(ProfileAddress address) => address.format();
