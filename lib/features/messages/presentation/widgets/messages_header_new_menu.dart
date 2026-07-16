import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Header action used on Messages and Live Chat tabs.
class MessagesHeaderNewMenu extends StatelessWidget {
  const MessagesHeaderNewMenu({
    super.key,
    required this.vcare,
    required this.onNewChat,
    required this.onNewGroup,
  });

  final VCareThemeExtension vcare;
  final VoidCallback onNewChat;
  final VoidCallback onNewGroup;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          onTap: onNewChat,
          child: MessagesHeaderNewMenuOption(
            icon: LucideIcons.userPlus,
            iconBackground: VCareColors.primary.withValues(alpha: 0.12),
            iconColor: VCareColors.primary,
            title: 'New chat',
            subtitle: 'Start a 1:1 conversation',
          ),
        ),
        PopupMenuItem<void>(
          onTap: onNewGroup,
          child: MessagesHeaderNewMenuOption(
            icon: LucideIcons.users,
            iconBackground: vcare.accent.withValues(alpha: 0.12),
            iconColor: vcare.accent,
            title: 'New group',
            subtitle: 'Chat with multiple people',
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.plus, size: 16, color: VCareColors.primary),
          const SizedBox(width: 4),
          Text(
            'New',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: VCareColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesHeaderNewMenuOption extends StatelessWidget {
  const MessagesHeaderNewMenuOption({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
