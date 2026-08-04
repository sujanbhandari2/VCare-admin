import 'package:intl/intl.dart';

/// Display pattern for date-only fields and pickers: `Aug 2, 1999`.
final DateFormat displayDateFormat = DateFormat('MMM d, y');

/// Formats a [DateTime] as `Aug 2, 1999`.
String formatDisplayDate(DateTime date) => displayDateFormat.format(date);

/// Parses common date strings and formats them for display as `Aug 2, 1999`.
///
/// Accepts ISO (`yyyy-MM-dd`, timestamps), US (`MM/dd/yyyy`), and the display
/// form itself. Returns `''` for null/empty input, or the original string if
/// parsing fails.
String formatDisplayDateString(String? input) {
  if (input == null || input.isEmpty) {
    return '';
  }
  final parsed = parseDisplayDate(input);
  if (parsed == null) {
    return input;
  }
  return formatDisplayDate(parsed);
}

/// Parses ISO, US numeric, or display-form date strings.
DateTime? parseDisplayDate(String? input) {
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
    // Fall through.
  }
  try {
    return displayDateFormat.parseStrict(input);
  } on FormatException {
    return null;
  }
}
