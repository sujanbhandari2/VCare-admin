/// Parity with vcareapp `lib/chat-date.ts`.
String formatRequestChatDateSeparator(DateTime date) {
  final now = DateTime.now();
  DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  final diffDays = startOfDay(now).difference(startOfDay(date)).inDays;

  if (diffDays == 0) return 'Today';
  if (diffDays == 1) return 'Yesterday';
  if (diffDays < 7) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[date.weekday - 1];
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
  final yearSuffix = now.year == date.year ? '' : ', ${date.year}';
  return '${months[date.month - 1]} ${date.day}$yearSuffix';
}

bool requestSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
