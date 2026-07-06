import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/shared/widgets/profile_avatar.dart';

class HomePageHeader extends StatelessWidget {
  const HomePageHeader({
    super.key,
    required this.profile,
    required this.unreadCount,
    this.greetingLabel = 'Welcome back',
    this.onProfileTap,
    this.onNotificationsTap,
    this.onSettingsTap,
    this.compact = false,
  });

  final HomeProfile profile;
  final int unreadCount;
  final String greetingLabel;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final avatarSize = compact ? 40.0 : 56.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, compact ? 8 : 16, 20, compact ? 8 : 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: vcare.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: ProfileAvatar(
                name: profile.fullName,
                photoUrl: profile.photoUrl,
                size: avatarSize,
                circular: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: compact
                      ? const SizedBox.shrink()
                      : Text(
                          greetingLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: vcare.mutedForeground,
                            height: 1.2,
                          ),
                        ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  style:
                      (compact
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.headlineMedium)
                          ?.copyWith(
                            fontSize: compact ? 16 : 20,
                            height: 1.1,
                          ) ??
                      const TextStyle(),
                  child: Text(
                    profile.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _IconButton(
            icon: LucideIcons.bell,
            onTap: onNotificationsTap,
            badge: unreadCount > 0,
          ),
          if (onSettingsTap != null)
            _IconButton(icon: LucideIcons.settings, onTap: onSettingsTap),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.onTap, this.badge = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 24),
              if (badge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: VCareColors.destructive,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: VCareColors.background,
                        width: 2,
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
