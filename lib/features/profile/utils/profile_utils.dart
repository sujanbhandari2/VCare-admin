import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';

/// US date format MM/DD/YYYY — parity with vcareapp formatUsDate.
String formatProfileDob(String? input) {
  if (input == null || input.isEmpty) {
    return '';
  }
  final parsed = DateTime.tryParse(input);
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
  final parsed = DateTime.tryParse(dob);
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
