import 'package:flutter/material.dart';

import 'package:flutter_template/core/styles/vcare_theme.dart';

/// Pill tab bar — parity with vcareapp `TabsList` on [ClientDetailPage].
class ClientDetailTabBar extends StatelessWidget {
  const ClientDetailTabBar({super.key, required this.controller});

  final TabController controller;

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
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: vcare.card,
            borderRadius: BorderRadius.circular(999),
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
          tabs: const [
            Tab(text: 'Memberships', height: 40),
            Tab(text: 'Billing', height: 40),
            Tab(text: 'Cases', height: 40),
            Tab(text: 'Documents', height: 40),
          ],
        ),
      ),
    );
  }
}

class ClientDetailTabBarHeader extends SliverPersistentHeaderDelegate {
  ClientDetailTabBarHeader({required this.tabBar});

  final ClientDetailTabBar tabBar;

  @override
  double get minExtent => ClientDetailTabBar.barHeight + 8;

  @override
  double get maxExtent => ClientDetailTabBar.barHeight + 8;

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
  bool shouldRebuild(covariant ClientDetailTabBarHeader oldDelegate) => false;
}
