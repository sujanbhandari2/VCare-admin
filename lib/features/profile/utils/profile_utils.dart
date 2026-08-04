import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/shared/utils/date_format_utils.dart';

/// Parses profile DOB from ISO, US (`MM/dd/yyyy`), or display (`MMM d, y`).
DateTime? parseProfileDob(String? input) => parseDisplayDate(input);

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

/// Display date format `Aug 2, 1999` for DOB fields and pickers.
String formatProfileDob(String? input) => formatDisplayDateString(input);

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

/// Profile edit gender options (UI labels) — parity with web PROFILE_GENDER_OPTIONS.
const profileGenderOptions = ['Male', 'Female', 'Others'];

/// Maps API gender (`MALE` / `FEMALE` / `OTHER`) to profile-edit UI labels.
String mapProfileGenderApiToUi(String? gender) {
  switch (gender?.trim().toUpperCase()) {
    case 'MALE':
      return 'Male';
    case 'FEMALE':
      return 'Female';
    case 'OTHER':
      return 'Others';
    default:
      return '';
  }
}

/// Maps profile-edit UI gender to API enum. Empty / unknown → null (omit).
String? mapProfileGenderUiToApi(String? gender) {
  switch (gender?.trim()) {
    case 'Male':
      return 'MALE';
    case 'Female':
      return 'FEMALE';
    case 'Others':
      return 'OTHER';
    default:
      return null;
  }
}
