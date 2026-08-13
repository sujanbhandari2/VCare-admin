import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class ProfileNavItem {
  const ProfileNavItem({
    required this.routeName,
    required this.label,
    required this.icon,
  });

  final String routeName;
  final String label;
  final IconData icon;
}

/// Parity with vcareapp PROFILE_NAV_ITEMS + ProfileSettingsNav.
const profileNavItems = <ProfileNavItem>[
  ProfileNavItem(
    routeName: AppRouter.careTeamName,
    label: 'Care Team',
    icon: LucideIcons.stethoscope,
  ),
  ProfileNavItem(
    routeName: AppRouter.idCardName,
    label: 'My Referral',
    icon: LucideIcons.creditCard,
  ),
  ProfileNavItem(
    routeName: AppRouter.documentsName,
    label: 'My Documents',
    icon: LucideIcons.folderOpen,
  ),
  // Temporarily hidden — restore when these profile destinations are enabled.
  // ProfileNavItem(
  //   routeName: AppRouter.notificationsName,
  //   label: 'Notifications',
  //   icon: LucideIcons.bell,
  // ),
  ProfileNavItem(
    routeName: AppRouter.savedProvidersName,
    label: 'Saved providers',
    icon: LucideIcons.heart,
  ),
  // ProfileNavItem(
  //   routeName: AppRouter.privacySecurityName,
  //   label: 'Privacy & security',
  //   icon: LucideIcons.shield,
  // ),
  // ProfileNavItem(
  //   routeName: AppRouter.helpSupportName,
  //   label: 'Help & support',
  //   icon: LucideIcons.helpCircle,
  // ),
];

class ProfileSettingsNav extends StatelessWidget {
  const ProfileSettingsNav({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.xxlAll,
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < profileNavItems.length; index++)
            _ProfileNavRow(
              item: profileNavItems[index],
              showDivider: index < profileNavItems.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ProfileNavRow extends StatelessWidget {
  const _ProfileNavRow({required this.item, required this.showDivider});

  final ProfileNavItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      children: [
        InkWell(
          onTap: () => context.pushNamed(item.routeName),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: context.vcare.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: vcare.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: vcare.border),
      ],
    );
  }
}
