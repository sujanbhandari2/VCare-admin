import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_formatters.dart';

class AdminDashboardTodoRow extends StatelessWidget {
  const AdminDashboardTodoRow({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onComplete,
    this.isCompleting = false,
  });

  final AdminDashboardTaskTodoItem item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final ValueChanged<String>? onComplete;
  final bool isCompleting;

  static const _rowBackground = Color(0xFFF6F3F0);

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final clientName = item.client?.name.trim().isNotEmpty == true
        ? item.client!.name.trim()
        : 'No client';
    final dueLabel = formatAdminDashboardDueLabel(item.dueDate);
    final isOverdue = item.itemType == AdminDashboardTodoItemType.taskOverdue;
    final priorityLabel = _priorityLabel(item.priority);
    final taskId = item.resource.id.trim();
    final canComplete = taskId.isNotEmpty && onComplete != null && !isCompleting;
    final canEdit =
        taskId.isNotEmpty &&
        onEdit != null &&
        item.status != AdminDashboardTaskStatus.completed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.mdAll,
        child: Ink(
          decoration: BoxDecoration(
            color: _rowBackground,
            borderRadius: VCareRadius.mdAll,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      // Checking a task can only ever complete it, so the tick
                      // stays on and locked until the request settles.
                      value: isCompleting,
                      onChanged: isCompleting
                          ? (_) {}
                          : canComplete
                          ? (checked) {
                              if (checked == true) {
                                onComplete!(taskId);
                              }
                            }
                          : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.user,
                                size: 11,
                                color: vcare.mutedForeground,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                clientName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: vcare.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          if (dueLabel.isNotEmpty)
                            Text(
                              dueLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isOverdue
                                    ? vcare.dangerScale.s500
                                    : vcare.warningScale.s700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (priorityLabel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.priority == AdminDashboardTaskPriority.urgent
                          ? vcare.dangerScale.s50
                          : vcare.warningScale.s50,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color:
                            item.priority == AdminDashboardTaskPriority.urgent
                            ? vcare.dangerScale.s200
                            : vcare.warningScale.s200,
                      ),
                    ),
                    child: Text(
                      priorityLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            item.priority == AdminDashboardTaskPriority.urgent
                            ? vcare.dangerScale.s500
                            : vcare.warningScale.s700,
                      ),
                    ),
                  ),
                ],
                if (isCompleting)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  if (canEdit)
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(LucideIcons.pencil, size: 14),
                      color: vcare.mutedForeground,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: 'Edit task',
                    ),
                  if (onTap != null)
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: vcare.mutedForeground,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _priorityLabel(AdminDashboardTaskPriority priority) {
    switch (priority) {
      case AdminDashboardTaskPriority.urgent:
        return 'Urgent';
      case AdminDashboardTaskPriority.high:
        return 'High';
      case AdminDashboardTaskPriority.low:
      case AdminDashboardTaskPriority.medium:
        return null;
    }
  }
}
