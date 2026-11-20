import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

class MyTasksFilterSheet extends StatefulWidget {
  const MyTasksFilterSheet({
    super.key,
    required this.categoryFilter,
    required this.statusFilter,
    required this.originFilter,
    required this.priorityFilter,
  });

  final MyTaskQueueCategoryFilter categoryFilter;
  final MyTaskStatus? statusFilter;
  final MyTaskOrigin? originFilter;
  final MyTaskPriority? priorityFilter;

  static Future<MyTasksFilterResult?> show(
    BuildContext context, {
    required MyTaskQueueCategoryFilter categoryFilter,
    required MyTaskStatus? statusFilter,
    required MyTaskOrigin? originFilter,
    required MyTaskPriority? priorityFilter,
  }) {
    return context.showBottomSheet<MyTasksFilterResult>(
      builder: (_) => MyTasksFilterSheet(
        categoryFilter: categoryFilter,
        statusFilter: statusFilter,
        originFilter: originFilter,
        priorityFilter: priorityFilter,
      ),
    );
  }

  @override
  State<MyTasksFilterSheet> createState() => _MyTasksFilterSheetState();
}

class MyTasksFilterResult {
  const MyTasksFilterResult({
    required this.categoryFilter,
    required this.statusFilter,
    required this.originFilter,
    required this.priorityFilter,
    this.clear = false,
  });

  final MyTaskQueueCategoryFilter categoryFilter;
  final MyTaskStatus? statusFilter;
  final MyTaskOrigin? originFilter;
  final MyTaskPriority? priorityFilter;
  final bool clear;
}

class _MyTasksFilterSheetState extends State<MyTasksFilterSheet> {
  late MyTaskQueueCategoryFilter _category;
  late MyTaskStatus? _status;
  late MyTaskOrigin? _origin;
  late MyTaskPriority? _priority;

  @override
  void initState() {
    super.initState();
    _category = widget.categoryFilter;
    _status = widget.statusFilter;
    _origin = widget.originFilter;
    _priority = widget.priorityFilter;
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.my_tasks_filters,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MyTaskQueueCategoryFilter>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: l10n.my_tasks_category,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in MyTaskQueueCategoryFilter.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MyTaskStatus?>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: l10n.my_tasks_status,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.my_tasks_all)),
                for (final value in MyTaskStatus.editableValues)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MyTaskOrigin?>(
              initialValue: _origin,
              decoration: InputDecoration(
                labelText: l10n.my_tasks_origin,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.my_tasks_all)),
                DropdownMenuItem(
                  value: MyTaskOrigin.custom,
                  child: Text(l10n.my_tasks_origin_custom),
                ),
                DropdownMenuItem(
                  value: MyTaskOrigin.system,
                  child: Text(l10n.my_tasks_origin_system),
                ),
              ],
              onChanged: (value) => setState(() => _origin = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MyTaskPriority?>(
              initialValue: _priority == MyTaskPriority.urgent
                  ? MyTaskPriority.high
                  : _priority,
              decoration: InputDecoration(
                labelText: l10n.my_tasks_priority,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.my_tasks_all)),
                DropdownMenuItem(
                  value: MyTaskPriority.high,
                  child: Text(l10n.my_tasks_priority_high),
                ),
                DropdownMenuItem(
                  value: MyTaskPriority.medium,
                  child: Text(l10n.my_tasks_priority_medium),
                ),
                DropdownMenuItem(
                  value: MyTaskPriority.low,
                  child: Text(l10n.my_tasks_priority_low),
                ),
              ],
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    text: l10n.my_tasks_clear,
                    onPressed: () {
                      Navigator.pop(
                        context,
                        const MyTasksFilterResult(
                          categoryFilter: MyTaskQueueCategoryFilter.all,
                          statusFilter: MyTaskStatus.toDo,
                          originFilter: null,
                          priorityFilter: null,
                          clear: true,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.elevated(
                    text: l10n.my_tasks_apply,
                    onPressed: () {
                      Navigator.pop(
                        context,
                        MyTasksFilterResult(
                          categoryFilter: _category,
                          statusFilter: _status,
                          originFilter: _origin,
                          priorityFilter: _priority,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Text(
              l10n.my_tasks_status_default_hint,
              style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
