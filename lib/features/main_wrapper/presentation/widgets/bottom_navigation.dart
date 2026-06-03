import 'package:flutter/material.dart';
import 'package:flutter_template/core/styles/app_colors.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

import 'package:flutter_template/features/main_wrapper/domain/enums/nav_item.dart';

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
      unselectedItemColor: AppColors.grey,
      selectedItemColor: !context.isDarkTheme
          ? context.theme.primaryColor
          : context.theme.colorScheme.onSurface,
      elevation: 5.0,
      showSelectedLabels: true,
      showUnselectedLabels: false,
      type: .fixed,
      items: items
          .map(
            (item) => _buildItem(item, context: context),
          )
          .toList(),
      onTap: (index) => onSelect(
        index,
        NavItem.values[index],
      ),
      currentIndex: currentNavItem.index,
    );
  }

  /// Helper function to convert nav item to bottom navigation bar item
  BottomNavigationBarItem _buildItem(NavItem item,
      {required BuildContext context}) {
    return item.toBottomNavigationBarItem(context);
  }
}
