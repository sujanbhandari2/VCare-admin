import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';

/// Primary bottom navigation items (vcare [MobileShell] mobile tab order).
enum NavItem {
  clients(path: AppRouter.clients, label: 'Clients', icon: LucideIcons.users),
  // Provider tab disabled for now — restore when Find Care returns to the
  // bottom navigation.
  // provider(
  //   path: AppRouter.findCare,
  //   label: 'Provider',
  //   icon: LucideIcons.search,
  // ),
  commission(
    path: AppRouter.commissions,
    label: 'Commission',
    icon: LucideIcons.wallet,
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
  profile(path: AppRouter.profile, label: 'Profile', icon: LucideIcons.user);
  // AVA tab disabled for now — restore when AVA returns to the bottom nav.
  // ava(path: AppRouter.ava, label: 'AVA', icon: LucideIcons.sparkles);

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

  /// Mobile bottom bar order: Clients, Commission, Home, Messages, Profile.
  static const List<NavItem> mobileTabs = [
    NavItem.clients,
    // NavItem.provider,
    NavItem.commission,
    NavItem.home,
    NavItem.messages,
    NavItem.profile,
  ];

  static NavItem fromBranchIndex(int index) => mobileTabs[index];

  static int branchIndexFor(NavItem item) => mobileTabs.indexOf(item);
}
