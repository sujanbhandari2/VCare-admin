import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/utils/my_task_formatters.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Task card for the My Tasks queue and Home preview.
///
/// [compact] uses a minimal Home layout: icon + title + badges, optional
/// description. Full cards keep assignee + client footer for the queue screen.
class MyTaskRow extends StatelessWidget {
  const MyTaskRow({
    super.key,
    required this.task,
    this.onTap,
    this.compact = false,
  });

  final MyTask task;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VCareRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: vcare.card,
            borderRadius: BorderRadius.circular(VCareRadius.lg),
            border: Border.all(color: vcare.border),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: compact
                ? _CompactTaskContent(task: task)
                : _FullTaskContent(task: task),
          ),
        ),
      ),
    );
  }
}

/// Home preview — icon, title, status badges, optional one-line description.
class _CompactTaskContent extends StatelessWidget {
  const _CompactTaskContent({required this.task});

  final MyTask task;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final description = task.description?.trim();
    final showDescription = description != null && description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                _categoryIcon(task),
                size: 16,
                color: vcare.mutedForeground,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  ..._statusBadges(context, task, includeDueSoon: true),
                ],
              ),
            ),
          ],
        ),
        if (showDescription) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              description,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: vcare.mutedForeground,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Full queue card — title, badges, description, assignee, client footer.
class _FullTaskContent extends StatelessWidget {
  const _FullTaskContent({required this.task});

  final MyTask task;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final description = task.description?.trim();
    final showDescription = description != null && description.isNotEmpty;
    final showClient = _hasClient(task);
    final badges = _statusBadges(context, task, includeDueSoon: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          task.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (badges.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: badges),
        ],
        if (showDescription) ...[
          const SizedBox(height: 8),
          Text(
            description,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: vcare.mutedForeground,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _AssignedToLine(
          name: resolveMyTaskPersonLabel(
            task.assignee,
            fallback: l10n.my_tasks_unassigned,
          ),
        ),
        if (showClient) ...[
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: vcare.border),
          const SizedBox(height: 12),
          _ClientFooter(task: task),
        ],
      ],
    );
  }
}

bool _hasClient(MyTask task) {
  final name = task.client?.name.trim();
  if (name != null && name.isNotEmpty) return true;
  final fallback = task.clientName?.trim();
  return fallback != null && fallback.isNotEmpty;
}

bool _isDueToday(MyTask task) {
  if (task.isOverdue || task.status.isTerminal) return false;
  final due = task.dueDate;
  if (due == null) return false;
  final now = DateTime.now();
  return due.year == now.year && due.month == now.month && due.day == now.day;
}

IconData _categoryIcon(MyTask task) {
  if (task.origin == MyTaskOrigin.system) return LucideIcons.bot;
  return switch (task.category) {
    MyTaskCategory.referralCase => LucideIcons.clipboardList,
    MyTaskCategory.membershipCase => LucideIcons.fileText,
    MyTaskCategory.clientCase => LucideIcons.user,
    MyTaskCategory.billingCase => LucideIcons.creditCard,
    MyTaskCategory.careCoordination => LucideIcons.heartHandshake,
    null => LucideIcons.listChecks,
  };
}

List<Widget> _statusBadges(
  BuildContext context,
  MyTask task, {
  required bool includeDueSoon,
}) {
  final l10n = context.appLocalization;
  final showPriority =
      task.priority == MyTaskPriority.high ||
      task.priority == MyTaskPriority.urgent;

  return [
    if (task.isOverdue && task.dueDate != null)
      _StatusBadge(
        label: _overdueBadgeLabel(l10n, task.dueDate!),
        tone: _BadgeTone.danger,
      ),
    if (includeDueSoon && _isDueToday(task))
      _StatusBadge(
        label: l10n.my_tasks_badge_due_today,
        tone: _BadgeTone.danger,
      ),
    if (task.isSnoozed)
      _StatusBadge(label: l10n.my_tasks_snoozed, tone: _BadgeTone.muted),
    if (showPriority)
      _StatusBadge(
        label: l10n.my_tasks_badge_high_priority,
        tone: _BadgeTone.danger,
      ),
  ];
}

String _overdueBadgeLabel(AppLocalizations l10n, DateTime dueDate) {
  final now = DateTime.now();
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(due).inDays;
  if (days <= 1) return l10n.my_tasks_badge_overdue_one_day;
  return l10n.my_tasks_badge_overdue_days(days);
}

enum _BadgeTone { danger, muted }

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.tone});

  final String label;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bg = switch (tone) {
      _BadgeTone.danger => vcare.dangerScale.s50,
      _BadgeTone.muted => vcare.muted,
    };
    final fg = switch (tone) {
      _BadgeTone.danger => vcare.dangerScale.s600,
      _BadgeTone.muted => vcare.mutedForeground,
    };
    final border = switch (tone) {
      _BadgeTone.danger => vcare.dangerScale.s200,
      _BadgeTone.muted => vcare.border,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(VCareRadius.full),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _AssignedToLine extends StatelessWidget {
  const _AssignedToLine({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
        children: [
          TextSpan(text: '${l10n.my_tasks_assigned_to} '),
          TextSpan(
            text: name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ClientFooter extends StatelessWidget {
  const _ClientFooter({required this.task});

  final MyTask task;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final name = task.displayClientName;
    final email = task.client?.email?.trim();

    return Row(
      children: [
        _InitialsAvatar(name: name, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: vcare.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: vcare.muted, shape: BoxShape.circle),
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: size * 0.3,
          fontWeight: FontWeight.w600,
          color: vcare.mutedForeground,
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final value = parts.first;
    return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
