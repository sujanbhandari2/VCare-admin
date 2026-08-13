import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Web-style Status / Priority dropdowns + Bookmarked toggle.
class CasesFilterBar extends StatelessWidget {
  const CasesFilterBar({
    super.key,
    required this.status,
    required this.priority,
    required this.bookmarkedOnly,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onBookmarkedOnlyChanged,
    required this.onClearFilters,
  });

  final CaseStatus? status;
  final CasePriority? priority;
  final bool bookmarkedOnly;
  final ValueChanged<CaseStatus?> onStatusChanged;
  final ValueChanged<CasePriority?> onPriorityChanged;
  final ValueChanged<bool> onBookmarkedOnlyChanged;
  final VoidCallback onClearFilters;

  static const double barHeight = 36;
  static const double controlHeight = 32;

  bool get _hasActiveFilters =>
      status != null || priority != null || bookmarkedOnly;

  static const _statusOptions = <(CaseStatus?, String)>[
    (null, 'All'),
    (CaseStatus.newCase, 'New'),
    (CaseStatus.requested, 'Requested'),
    (CaseStatus.inProgress, 'In Progress'),
    (CaseStatus.closed, 'Closed'),
    (CaseStatus.deleted, 'Deleted'),
  ];

  static const _priorityOptions = <(CasePriority?, String)>[
    (null, 'All'),
    (CasePriority.urgent, 'Urgent'),
    (CasePriority.high, 'High'),
    (CasePriority.medium, 'Medium'),
    (CasePriority.low, 'Low'),
  ];

  String get _statusLabel {
    for (final option in _statusOptions) {
      if (option.$1 == status) return option.$2;
    }
    return 'All';
  }

  String get _priorityLabel {
    for (final option in _priorityOptions) {
      if (option.$1 == priority) return option.$2;
    }
    return 'All';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: barHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterDropdown(
            prefix: 'Status:',
            valueLabel: _statusLabel,
            selectedKey: status?.name ?? 'all',
            options: [
              for (final option in _statusOptions)
                (option.$1?.name ?? 'all', option.$2),
            ],
            onSelected: (key) {
              if (key == 'all') {
                onStatusChanged(null);
                return;
              }
              onStatusChanged(
                CaseStatus.values.firstWhere((value) => value.name == key),
              );
            },
          ),
          const SizedBox(width: 8),
          _FilterDropdown(
            prefix: 'Priority:',
            valueLabel: _priorityLabel,
            selectedKey: priority?.name ?? 'all',
            options: [
              for (final option in _priorityOptions)
                (option.$1?.name ?? 'all', option.$2),
            ],
            onSelected: (key) {
              if (key == 'all') {
                onPriorityChanged(null);
                return;
              }
              onPriorityChanged(
                CasePriority.values.firstWhere((value) => value.name == key),
              );
            },
          ),
          const SizedBox(width: 8),
          _BookmarkToggle(
            selected: bookmarkedOnly,
            onTap: () => onBookmarkedOnlyChanged(!bookmarkedOnly),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 8),
            _ClearFiltersButton(onTap: onClearFilters),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.prefix,
    required this.valueLabel,
    required this.selectedKey,
    required this.options,
    required this.onSelected,
  });

  final String prefix;
  final String valueLabel;
  final String selectedKey;
  final List<(String, String)> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final theme = Theme.of(context);

    return Center(
      child: PopupMenuButton<String>(
        tooltip: prefix,
        offset: const Offset(0, 36),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: VCareRadius.lgAll,
          side: BorderSide(color: vcare.border),
        ),
        color: theme.colorScheme.surface,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        onSelected: onSelected,
        itemBuilder: (context) {
          return [
            for (final option in options)
              PopupMenuItem<String>(
                value: option.$1,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _DropdownMenuRow(
                  label: option.$2,
                  selected: option.$1 == selectedKey,
                ),
              ),
          ];
        },
        child: _FilterTrigger(
          prefix: prefix,
          valueLabel: valueLabel,
          active: selectedKey != 'all',
        ),
      ),
    );
  }
}

class _DropdownMenuRow extends StatelessWidget {
  const _DropdownMenuRow({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? context.vcare.muted.withValues(alpha: 0.85)
            : Colors.transparent,
        borderRadius: VCareRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: selected
                  ? Icon(
                      LucideIcons.check,
                      size: 14,
                      color: onSurface,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? onSurface : vcare.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTrigger extends StatelessWidget {
  const _FilterTrigger({
    required this.prefix,
    required this.valueLabel,
    required this.active,
  });

  final String prefix;
  final String valueLabel;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      height: CasesFilterBar.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? context.vcare.primary.withValues(alpha: 0.45) : vcare.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefix,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: vcare.mutedForeground,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            valueLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: vcare.mutedForeground,
          ),
        ],
      ),
    );
  }
}

class _BookmarkToggle extends StatelessWidget {
  const _BookmarkToggle({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Center(
      child: Material(
        color: selected
            ? context.vcare.primary.withValues(alpha: 0.12)
            : vcare.card,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: CasesFilterBar.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? context.vcare.primary : vcare.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.bookmark,
                  size: 13,
                  color: selected
                      ? context.vcare.primary
                      : vcare.mutedForeground,
                ),
                const SizedBox(width: 5),
                Text(
                  'Bookmarked',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? context.vcare.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearFiltersButton extends StatelessWidget {
  const _ClearFiltersButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, CasesFilterBar.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: vcare.mutedForeground,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.x, size: 13),
            SizedBox(width: 4),
            Text(
              'Clear filters',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class CasesFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  CasesFilterHeaderDelegate({
    required this.status,
    required this.priority,
    required this.bookmarkedOnly,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onBookmarkedOnlyChanged,
    required this.onClearFilters,
  });

  final CaseStatus? status;
  final CasePriority? priority;
  final bool bookmarkedOnly;
  final ValueChanged<CaseStatus?> onStatusChanged;
  final ValueChanged<CasePriority?> onPriorityChanged;
  final ValueChanged<bool> onBookmarkedOnlyChanged;
  final VoidCallback onClearFilters;

  @override
  double get minExtent => CasesFilterBar.barHeight + 8;

  @override
  double get maxExtent => CasesFilterBar.barHeight + 8;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: CasesFilterBar(
          status: status,
          priority: priority,
          bookmarkedOnly: bookmarkedOnly,
          onStatusChanged: onStatusChanged,
          onPriorityChanged: onPriorityChanged,
          onBookmarkedOnlyChanged: onBookmarkedOnlyChanged,
          onClearFilters: onClearFilters,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CasesFilterHeaderDelegate oldDelegate) {
    return status != oldDelegate.status ||
        priority != oldDelegate.priority ||
        bookmarkedOnly != oldDelegate.bookmarkedOnly;
  }
}
