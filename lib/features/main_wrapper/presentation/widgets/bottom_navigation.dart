import 'package:flutter/material.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

import 'package:vcare_admin/features/main_wrapper/domain/enums/nav_item.dart';

/// BottomNavigation
///
class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    required this.items,
    required this.currentNavItem,
    required this.onSelect,
  });

  /// List of nav items for bottom navigation
  ///
  final List<NavItem> items;

  /// Currently active nav item
  ///
  final NavItem currentNavItem;

  /// Function to handle onSelect callback
  ///
  final void Function(int index, NavItem item) onSelect;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      unselectedItemColor: context.vcare.mutedForeground,
      selectedItemColor: !context.isDarkTheme
          ? context.theme.colorScheme.primary
          : context.theme.colorScheme.onSurface,
      elevation: 5.0,
      showSelectedLabels: true,
      showUnselectedLabels: false,
      type: .fixed,
      items: items.map((item) => _buildItem(item, context: context)).toList(),
      onTap: (index) => onSelect(index, NavItem.values[index]),
      currentIndex: currentNavItem.index,
    );
  }

  /// Helper function to convert nav item to bottom navigation bar item
  BottomNavigationBarItem _buildItem(
    NavItem item, {
    required BuildContext context,
  }) {
    return item.toBottomNavigationBarItem(context);
  }
}
