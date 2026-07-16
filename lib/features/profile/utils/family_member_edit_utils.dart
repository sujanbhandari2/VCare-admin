const relationshipOptions = [
  'Spouse',
  'Child',
  'Parent',
  'Sibling',
  'Other',
];

const genderOptions = [
  'MALE',
  'FEMALE',
  'OTHER',
];

const dobMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const maxProfilePhotoBytes = 25 * 1024 * 1024;

String get maxProfilePhotoLabel => '${maxProfilePhotoBytes ~/ (1024 * 1024)}MB';

List<int> dobYears() {
  final currentYear = DateTime.now().year;
  return List.generate(120, (index) => currentYear - index);
}

int daysInMonth(String month, String year) {
  final monthNumber = int.tryParse(month);
  final yearNumber = int.tryParse(year) ?? DateTime.now().year;
  if (monthNumber == null || monthNumber < 1 || monthNumber > 12) {
    return 31;
  }
  return DateTime(yearNumber, monthNumber + 1, 0).day;
}

String toIsoDob(String month, String day, String year) {
  if (month.isEmpty || day.isEmpty || year.isEmpty) {
    return '';
  }
  final monthNumber = int.parse(month);
  final dayNumber = int.parse(day);
  return '$year-${monthNumber.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
}

({String month, String day, String year}) fromIsoDob(String iso) {
  if (iso.isEmpty) {
    return (month: '', day: '', year: '');
  }
  final parts = iso.split('-');
  if (parts.length != 3) {
    return (month: '', day: '', year: '');
  }
  return (
    month: int.parse(parts[1]).toString(),
    day: int.parse(parts[2]).toString(),
    year: parts[0],
  );
}
