import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Pill tab bar — Notes | Files | Tasks with count badges.
///
/// Icons and badge counts mirror the web console `mainTabs` config.
class CaseDetailTabBar extends StatelessWidget {
  const CaseDetailTabBar({
    super.key,
    required this.controller,
    this.notesCount,
    this.filesCount,
    this.tasksCount,
  });

  final TabController controller;
  final int? notesCount;
  final int? filesCount;
  final int? tasksCount;

  static const double barHeight = 48;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.muted,
        borderRadius: VCareRadius.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: vcare.card,
            borderRadius: VCareRadius.fullAll,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          labelColor: onSurface,
          unselectedLabelColor: vcare.mutedForeground,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          labelPadding: EdgeInsets.zero,
          tabs: [
            for (var index = 0; index < 3; index++)
              Tab(
                height: 40,
                child: AnimatedBuilder(
                  animation: controller.animation ?? controller,
                  builder: (context, _) => _TabLabel(
                    icon: _tabIcons[index],
                    label: _tabLabels[index],
                    count: _tabCounts[index],
                    isSelected: controller.index == index,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const List<IconData> _tabIcons = [
    LucideIcons.fileText,
    LucideIcons.folderOpen,
    LucideIcons.checkSquare,
  ];

  static const List<String> _tabLabels = ['Notes', 'Files', 'Tasks'];

  List<int?> get _tabCounts => [notesCount, filesCount, tasksCount];
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final int? count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final value = count ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 6),
        Text(label),
        const SizedBox(width: 6),
        Container(
          constraints: const BoxConstraints(minWidth: 18),
          height: 18,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? vcare.primary
                : vcare.mutedForeground.withValues(alpha: 0.12),
            borderRadius: VCareRadius.fullAll,
          ),
          child: Text(
            value > 99 ? '99+' : '$value',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : vcare.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

class CaseDetailTabBarHeader extends SliverPersistentHeaderDelegate {
  CaseDetailTabBarHeader({required this.tabBar});

  final CaseDetailTabBar tabBar;

  @override
  double get minExtent => CaseDetailTabBar.barHeight + 8;

  @override
  double get maxExtent => CaseDetailTabBar.barHeight + 8;

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
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CaseDetailTabBarHeader oldDelegate) {
    return oldDelegate.tabBar.notesCount != tabBar.notesCount ||
        oldDelegate.tabBar.filesCount != tabBar.filesCount ||
        oldDelegate.tabBar.tasksCount != tabBar.tasksCount ||
        oldDelegate.tabBar.controller != tabBar.controller;
  }
}
