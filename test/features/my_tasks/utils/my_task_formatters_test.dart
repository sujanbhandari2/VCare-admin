import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/my_tasks/utils/my_task_formatters.dart';
import 'package:vcare_admin/l10n/app_localizations_en.dart';

void main() {
  group('formatMyTaskDueLabel', () {
    final now = DateTime(2026, 3, 10, 12);

    test('formats overdue, today, tomorrow, and future days', () {
      expect(formatMyTaskDueLabel(DateTime(2026, 3, 8), now), '2d overdue');
      expect(formatMyTaskDueLabel(DateTime(2026, 3, 10), now), 'today');
      expect(formatMyTaskDueLabel(DateTime(2026, 3, 11), now), 'tomorrow');
      expect(formatMyTaskDueLabel(DateTime(2026, 3, 14), now), 'in 4d');
    });
  });

  group('localizedMyTaskDueLabel', () {
    final now = DateTime(2026, 3, 10, 12);
    final l10n = AppLocalizationsEn();

    test('uses localization strings', () {
      expect(
        localizedMyTaskDueLabel(l10n, DateTime(2026, 3, 8), now),
        l10n.my_tasks_due_overdue(2),
      );
      expect(
        localizedMyTaskDueLabel(l10n, DateTime(2026, 3, 10), now),
        l10n.my_tasks_due_today,
      );
      expect(
        MyTaskSnoozePreset.tomorrow.localizedLabel(l10n),
        l10n.my_tasks_snooze_tomorrow,
      );
    });
  });

  group('isMyTaskDueDateValid', () {
    final now = DateTime(2026, 3, 10, 12);

    test('allows future dates and unchanged existing past dates', () {
      expect(
        isMyTaskDueDateValid(dueDate: DateTime(2026, 3, 11), now: now),
        isTrue,
      );
      expect(
        isMyTaskDueDateValid(
          dueDate: DateTime(2026, 3, 9),
          originalDueDate: DateTime(2026, 3, 9),
          now: now,
        ),
        isTrue,
      );
      expect(
        isMyTaskDueDateValid(dueDate: DateTime(2026, 3, 9), now: now),
        isFalse,
      );
    });
  });
}
