import 'package:intl/intl.dart';

import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';

/// Preview limit for the Home My Tasks card.
const myTasksWidgetPreviewLimit = 3;

/// Default page size for the full My Tasks queue.
const myTasksPageSize = 25;

/// Due label — parity with admin dashboard / web queue due chips.
/// Prefer [localizedMyTaskDueLabel] in presentation UI.
String formatMyTaskDueLabel(DateTime dueDate, [DateTime? now]) {
  final diff = _myTaskDueDayDiff(dueDate, now);

  if (diff < 0) {
    final days = diff.abs();
    return days == 1 ? '1d overdue' : '${days}d overdue';
  }
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  return 'in ${diff}d';
}

/// Localized due chip label for presentation widgets.
String localizedMyTaskDueLabel(
  AppLocalizations l10n,
  DateTime dueDate, [
  DateTime? now,
]) {
  final diff = _myTaskDueDayDiff(dueDate, now);

  if (diff < 0) return l10n.my_tasks_due_overdue(diff.abs());
  if (diff == 0) return l10n.my_tasks_due_today;
  if (diff == 1) return l10n.my_tasks_due_tomorrow;
  return l10n.my_tasks_due_in_days(diff);
}

int _myTaskDueDayDiff(DateTime dueDate, [DateTime? now]) {
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(
    (now ?? DateTime.now()).year,
    (now ?? DateTime.now()).month,
    (now ?? DateTime.now()).day,
  );
  return due.difference(today).inDays;
}

String formatMyTaskDateTime(DateTime date) {
  return DateFormat('MMM d, yyyy · h:mm a').format(date);
}

String formatMyTaskShortDate(DateTime date) {
  return DateFormat('MMM d').format(date);
}

/// Snooze preset durations — mirrors web follow-up options used most often.
enum MyTaskSnoozePreset {
  tomorrow,
  threeDays,
  fiveDays,
  nextWeek,
  custom;

  /// English fallback label; prefer [localizedLabel] in UI.
  String get label => switch (this) {
    MyTaskSnoozePreset.tomorrow => 'Tomorrow',
    MyTaskSnoozePreset.threeDays => 'In 3 days',
    MyTaskSnoozePreset.fiveDays => 'In 5 days',
    MyTaskSnoozePreset.nextWeek => 'Next week',
    MyTaskSnoozePreset.custom => 'Custom date',
  };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MyTaskSnoozePreset.tomorrow => l10n.my_tasks_snooze_tomorrow,
    MyTaskSnoozePreset.threeDays => l10n.my_tasks_snooze_three_days,
    MyTaskSnoozePreset.fiveDays => l10n.my_tasks_snooze_five_days,
    MyTaskSnoozePreset.nextWeek => l10n.my_tasks_snooze_next_week,
    MyTaskSnoozePreset.custom => l10n.my_tasks_snooze_custom,
  };

  DateTime? resolve([DateTime? now]) {
    final base = now ?? DateTime.now();
    return switch (this) {
      MyTaskSnoozePreset.tomorrow => DateTime(
        base.year,
        base.month,
        base.day + 1,
        9,
      ),
      MyTaskSnoozePreset.threeDays => DateTime(
        base.year,
        base.month,
        base.day + 3,
        9,
      ),
      MyTaskSnoozePreset.fiveDays => DateTime(
        base.year,
        base.month,
        base.day + 5,
        9,
      ),
      MyTaskSnoozePreset.nextWeek => DateTime(
        base.year,
        base.month,
        base.day + 7,
        9,
      ),
      MyTaskSnoozePreset.custom => null,
    };
  }
}

bool isMyTaskDueDateValid({
  required DateTime? dueDate,
  DateTime? originalDueDate,
  DateTime? now,
}) {
  if (dueDate == null) return true;
  final reference = now ?? DateTime.now();
  if (dueDate.isAfter(reference)) return true;
  return originalDueDate != null && originalDueDate.isAtSameMomentAs(dueDate);
}

String resolveMyTaskPersonLabel(
  MyTaskPerson? person, {
  String fallback = 'Unassigned',
}) {
  if (person == null) return fallback;
  final name = person.displayName.trim();
  return name.isEmpty ? fallback : name;
}
