import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';

/// Individuals / Groups filter — parity with web `ClientsPanel` tabs.
class ClientsTypeFilterBar extends StatelessWidget {
  const ClientsTypeFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ClientListType selected;
  final ValueChanged<ClientListType> onChanged;

  static const double barHeight = 48;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _FilterChip(
                label: 'Individuals',
                selected: selected == ClientListType.individual,
                selectedColor: vcare.card,
                selectedTextColor: onSurface,
                unselectedTextColor: vcare.mutedForeground,
                onTap: () => onChanged(ClientListType.individual),
              ),
            ),
            Expanded(
              child: _FilterChip(
                label: 'Groups',
                selected: selected == ClientListType.group,
                selectedColor: vcare.card,
                selectedTextColor: onSurface,
                unselectedTextColor: vcare.mutedForeground,
                onTap: () => onChanged(ClientListType.group),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedColor : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? selectedTextColor : unselectedTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClientsTypeFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  ClientsTypeFilterHeaderDelegate({
    required this.selected,
    required this.onChanged,
  });

  final ClientListType selected;
  final ValueChanged<ClientListType> onChanged;

  @override
  double get minExtent => ClientsTypeFilterBar.barHeight + 8;

  @override
  double get maxExtent => ClientsTypeFilterBar.barHeight + 8;

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
        child: ClientsTypeFilterBar(
          selected: selected,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant ClientsTypeFilterHeaderDelegate oldDelegate) {
    return selected != oldDelegate.selected;
  }
}
