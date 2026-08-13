import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_todo_row.dart';

AdminDashboardTaskTodoItem _task({
  AdminDashboardTaskStatus status = AdminDashboardTaskStatus.newTask,
}) {
  return AdminDashboardTaskTodoItem(
    id: 'task-overdue:task-1',
    title: 'Membership follow-up',
    description: '',
    occurredAt: DateTime(2026, 7, 10),
    resource: const AdminDashboardTodoResource(type: 'TASK', id: 'task-1'),
    itemType: AdminDashboardTodoItemType.taskOverdue,
    priority: AdminDashboardTaskPriority.urgent,
    status: status,
    dueDate: DateTime(2026, 7, 10),
    client: const AdminDashboardTodoClientPreview(
      id: 'client-1',
      name: 'Merritt Vance',
    ),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [VCareThemeExtension.light]),
    home: Scaffold(body: child),
  );
}

void main() {
  group('AdminDashboardTodoRow', () {
    testWidgets('checking the box completes the task', (tester) async {
      final completed = <String>[];

      await tester.pumpWidget(
        _wrap(
          AdminDashboardTodoRow(
            item: _task(),
            onComplete: completed.add,
          ),
        ),
      );

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(completed, ['task-1']);
    });

    testWidgets('stays ticked and locked while completing', (tester) async {
      var completions = 0;

      await tester.pumpWidget(
        _wrap(
          AdminDashboardTodoRow(
            item: _task(),
            isCompleting: true,
            onComplete: (_) => completions += 1,
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
      expect(checkbox.onChanged, isNotNull);

      // Tapping again cannot untick it or fire another request.
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(completions, 0);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the edit action only when the task is open', (
      tester,
    ) async {
      var edits = 0;

      await tester.pumpWidget(
        _wrap(
          AdminDashboardTodoRow(
            item: _task(),
            onEdit: () => edits += 1,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Edit task'));
      await tester.pump();
      expect(edits, 1);

      await tester.pumpWidget(
        _wrap(
          AdminDashboardTodoRow(
            item: _task(status: AdminDashboardTaskStatus.completed),
            onEdit: () => edits += 1,
          ),
        ),
      );

      expect(find.byTooltip('Edit task'), findsNothing);
    });
  });
}
