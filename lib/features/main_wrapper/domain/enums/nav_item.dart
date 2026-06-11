import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';

/// Primary bottom navigation items (vcare [MobileShell] mobile tab order).
enum NavItem {
  clients(path: AppRouter.clients, label: 'Clients', icon: LucideIcons.users),
  provider(
    path: AppRouter.findCare,
    label: 'Provider',
    icon: LucideIcons.search,
  ),
  home(
    path: AppRouter.home,
    label: 'Home',
    icon: LucideIcons.home,
    isCenter: true,
  ),
  messages(
    path: AppRouter.messages,
    label: 'Messages',
    icon: LucideIcons.messageCircle,
  ),
  ava(path: AppRouter.ava, label: 'AVA', icon: LucideIcons.sparkles);

  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    this.isCenter = false,
  });

  final String path;
  final String label;
  final IconData icon;
  final bool isCenter;

  /// Mobile bottom bar order: Clients, Provider, Home, Messages, AVA.
  static const List<NavItem> mobileTabs = [
    NavItem.clients,
    NavItem.provider,
    NavItem.home,
    NavItem.messages,
    NavItem.ava,
  ];

  static NavItem fromBranchIndex(int index) => mobileTabs[index];

  static int branchIndexFor(NavItem item) => mobileTabs.indexOf(item);
}
