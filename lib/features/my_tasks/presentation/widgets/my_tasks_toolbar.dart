import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Search + quick-filter toolbar — visual parity with the web `/tasks` queue.
class MyTasksToolbar extends StatelessWidget {
  const MyTasksToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenAdvancedFilters,
    required this.hasAdvancedFilters,
    required this.hasOverdueQuickFilter,
    required this.hasSnoozedQuickFilter,
    required this.ownerFilter,
    required this.currentUserId,
    required this.currentUserName,
    required this.assignees,
    required this.onToggleQuickFilter,
    required this.onOwnerFilterChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenAdvancedFilters;
  final bool hasAdvancedFilters;
  final bool hasOverdueQuickFilter;
  final bool hasSnoozedQuickFilter;
  final MyTaskOwnerFilter ownerFilter;
  final String? currentUserId;
  final String? currentUserName;
  final List<AssociatedUser> assignees;
  final ValueChanged<MyTaskQuickFilter> onToggleQuickFilter;
  final ValueChanged<MyTaskOwnerFilter> onOwnerFilterChanged;

  static const double _wideBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalization;

    final chips = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MyTasksOutlineChip(
          label: l10n.my_tasks_overdue,
          icon: LucideIcons.alertTriangle,
          selected: hasOverdueQuickFilter,
          onTap: () => onToggleQuickFilter(MyTaskQuickFilter.overdue),
        ),
        const SizedBox(width: 8),
        MyTasksOutlineChip(
          label: l10n.my_tasks_snoozed,
          icon: LucideIcons.clock3,
          selected: hasSnoozedQuickFilter,
          onTap: () => onToggleQuickFilter(MyTaskQuickFilter.snoozed),
        ),
        const SizedBox(width: 8),
        MyTasksOwnerChip(
          ownerFilter: ownerFilter,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          assignees: assignees,
          onChanged: onOwnerFilterChanged,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        final search = MyTasksSearchField(
          controller: searchController,
          onChanged: onSearchChanged,
          onOpenFilters: onOpenAdvancedFilters,
          hasAdvancedFilters: hasAdvancedFilters,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 10),
              chips,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: chips,
            ),
          ],
        );
      },
    );
  }
}

class MyTasksSearchField extends StatelessWidget {
  const MyTasksSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onOpenFilters,
    required this.hasAdvancedFilters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilters;
  final bool hasAdvancedFilters;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final radius = BorderRadius.circular(VCareRadius.lg);

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: l10n.my_tasks_search_hint,
          hintStyle: TextStyle(fontSize: 14, color: vcare.mutedForeground),
          filled: true,
          fillColor: vcare.card,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 10,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 16,
            color: vcare.mutedForeground,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: IconButton(
            onPressed: onOpenFilters,
            tooltip: l10n.my_tasks_filters,
            visualDensity: VisualDensity.compact,
            icon: Badge(
              isLabelVisible: hasAdvancedFilters,
              smallSize: 8,
              child: Icon(
                LucideIcons.slidersHorizontal,
                size: 16,
                color: hasAdvancedFilters
                    ? vcare.primary
                    : vcare.mutedForeground,
              ),
            ),
          ),
          border: border(vcare.border),
          enabledBorder: border(vcare.border),
          focusedBorder: border(vcare.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Outline pill chip matching the web queue filter buttons.
class MyTasksOutlineChip extends StatelessWidget {
  const MyTasksOutlineChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final color = selected ? vcare.primary : vcare.mutedForeground;
    final borderColor = selected ? vcare.primary : vcare.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VCareRadius.full),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? vcare.primary.withValues(alpha: 0.06)
                : vcare.card,
            borderRadius: BorderRadius.circular(VCareRadius.full),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Assignee filter — parity with web `QueueOwnerFilter`.
class MyTasksOwnerChip extends StatelessWidget {
  const MyTasksOwnerChip({
    super.key,
    required this.ownerFilter,
    required this.currentUserId,
    required this.currentUserName,
    required this.assignees,
    required this.onChanged,
  });

  final MyTaskOwnerFilter ownerFilter;
  final String? currentUserId;
  final String? currentUserName;
  final List<AssociatedUser> assignees;
  final ValueChanged<MyTaskOwnerFilter> onChanged;

  bool get _showSelection => ownerFilter is! MyTaskOwnerFilterAll;

  bool get _showClear =>
      ownerFilter is MyTaskOwnerFilterUnassigned ||
      ownerFilter is MyTaskOwnerFilterUser;

  String _triggerLabel(AppLocalizations l10n) {
    if (ownerFilter is MyTaskOwnerFilterMe) return l10n.my_tasks_assigned_to_me;
    if (ownerFilter is MyTaskOwnerFilterUnassigned) {
      return l10n.my_tasks_unassigned;
    }
    if (ownerFilter is MyTaskOwnerFilterUser) {
      final id = (ownerFilter as MyTaskOwnerFilterUser).userId;
      for (final user in assignees) {
        if (user.id == id) {
          return l10n.my_tasks_assigned_to_name(user.displayName);
        }
      }
      return l10n.my_tasks_assigned_to_name(l10n.my_tasks_team_member);
    }
    return l10n.my_tasks_filter_by_assignee;
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await MyTasksOwnerFilterSheet.show(
      context,
      ownerFilter: ownerFilter,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      assignees: assignees,
    );
    if (selected == null) return;
    onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final selected = _showSelection;
    final color = selected ? vcare.primary : vcare.mutedForeground;
    final borderColor = selected ? vcare.primary : vcare.border;
    final bg = selected ? vcare.primary.withValues(alpha: 0.06) : vcare.card;

    return Tooltip(
      message: _triggerLabel(l10n),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(VCareRadius.full),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _openPicker(context),
                borderRadius: BorderRadius.horizontal(
                  left: const Radius.circular(VCareRadius.full),
                  right: Radius.circular(_showClear ? 0 : VCareRadius.full),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: selected ? 10 : 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.users, size: 16, color: color),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            _triggerLabel(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_showClear)
                InkWell(
                  onTap: () => onChanged(MyTaskOwnerFilter.me),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(VCareRadius.full),
                  ),
                  child: Tooltip(
                    message: l10n.my_tasks_clear_assignee_filter,
                    child: SizedBox(
                      width: 32,
                      height: 38,
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: color.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyTasksOwnerFilterSheet extends StatefulWidget {
  const MyTasksOwnerFilterSheet({
    super.key,
    required this.ownerFilter,
    required this.currentUserId,
    required this.currentUserName,
    required this.assignees,
  });

  final MyTaskOwnerFilter ownerFilter;
  final String? currentUserId;
  final String? currentUserName;
  final List<AssociatedUser> assignees;

  static Future<MyTaskOwnerFilter?> show(
    BuildContext context, {
    required MyTaskOwnerFilter ownerFilter,
    required String? currentUserId,
    required String? currentUserName,
    required List<AssociatedUser> assignees,
  }) {
    return context.showBottomSheet<MyTaskOwnerFilter>(
      isScrollControlled: true,
      maxHeightFactor: 0.72,
      builder: (_) => MyTasksOwnerFilterSheet(
        ownerFilter: ownerFilter,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        assignees: assignees,
      ),
    );
  }

  @override
  State<MyTasksOwnerFilterSheet> createState() =>
      _MyTasksOwnerFilterSheetState();
}

class _MyTasksOwnerFilterSheetState extends State<MyTasksOwnerFilterSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_OwnerOption> _options(AppLocalizations l10n) {
    final meName = (widget.currentUserName?.trim().isNotEmpty == true)
        ? widget.currentUserName!.trim()
        : l10n.my_tasks_assigned_to_me;

    final others =
        widget.assignees
            .where((user) => user.id != widget.currentUserId)
            .toList(growable: false)
          ..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );

    return [
      _OwnerOption(
        filter: MyTaskOwnerFilter.all,
        label: l10n.my_tasks_all_members,
      ),
      _OwnerOption(
        filter: MyTaskOwnerFilter.me,
        label: l10n.my_tasks_you_label(meName),
        role: null,
      ),
      for (final user in others)
        _OwnerOption(
          filter: MyTaskOwnerFilter.user(user.id),
          label: user.displayName,
          role: user.role.trim().isEmpty ? null : user.role.trim(),
        ),
      _OwnerOption(
        filter: MyTaskOwnerFilter.unassigned,
        label: l10n.my_tasks_unassigned,
      ),
    ];
  }

  List<_OwnerOption> _filtered(AppLocalizations l10n) {
    final options = _options(l10n);
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return options;
    return options
        .where(
          (option) =>
              option.label.toLowerCase().contains(q) ||
              (option.role?.toLowerCase().contains(q) ?? false),
        )
        .toList(growable: false);
  }

  bool _isSelected(_OwnerOption option) {
    final current = widget.ownerFilter;
    final next = option.filter;
    if (current is MyTaskOwnerFilterMe && next is MyTaskOwnerFilterMe) {
      return true;
    }
    if (current is MyTaskOwnerFilterAll && next is MyTaskOwnerFilterAll) {
      return true;
    }
    if (current is MyTaskOwnerFilterUnassigned &&
        next is MyTaskOwnerFilterUnassigned) {
      return true;
    }
    if (current is MyTaskOwnerFilterUser && next is MyTaskOwnerFilterUser) {
      return current.userId == next.userId;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final filtered = _filtered(l10n);
    final viewingOther =
        widget.ownerFilter is MyTaskOwnerFilterUser ||
        widget.ownerFilter is MyTaskOwnerFilterUnassigned;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.my_tasks_filter_by_assignee,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  color: vcare.mutedForeground,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.my_tasks_search_team_members,
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.my_tasks_no_team_members,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: vcare.mutedForeground),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(bottom: viewingOther ? 0 : 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final selected = _isSelected(option);
                      final showDivider =
                          option.filter is MyTaskOwnerFilterUnassigned &&
                          index > 0 &&
                          filtered[index - 1].filter
                              is! MyTaskOwnerFilterUnassigned;

                      return Column(
                        children: [
                          if (showDivider)
                            Divider(height: 1, color: vcare.border),
                          Material(
                            color: selected
                                ? vcare.primary
                                : Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  Navigator.pop(context, option.filter),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      child: selected
                                          ? Icon(
                                              LucideIcons.check,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.onPrimary,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: selected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary
                                                  : null,
                                            ),
                                          ),
                                          if (option.role != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              option.role!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: selected
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary
                                                          .withValues(
                                                            alpha: 0.8,
                                                          )
                                                    : vcare.mutedForeground,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (viewingOther) ...[
            Divider(height: 1, color: vcare.border),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 4, 8, bottomInset + 8),
              child: TextButton(
                onPressed: () => Navigator.pop(context, MyTaskOwnerFilter.me),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.my_tasks_assigned_to_me),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnerOption {
  const _OwnerOption({required this.filter, required this.label, this.role});

  final MyTaskOwnerFilter filter;
  final String label;
  final String? role;
}
