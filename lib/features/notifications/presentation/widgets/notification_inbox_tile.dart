import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/notifications/domain/entities/notification_item.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class NotificationInboxTile extends StatelessWidget {
  const NotificationInboxTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.vcare.card,
      borderRadius: VCareRadius.xlAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.xlAll,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: VCareRadius.xlAll,
            border: Border.all(color: context.vcare.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIconBubble(
                icon: _notificationIcon(notification.type),
                background: notification.read
                    ? context.vcare.muted
                    : context.vcare.primary.withValues(alpha: 0.1),
                color: notification.read
                    ? context.vcare.mutedForeground
                    : context.vcare.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(color: context.vcare.mutedForeground),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.MMMd().add_jm().format(
                        notification.createdAt.toLocal(),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: context.vcare.destructive,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'message':
        return LucideIcons.messageCircle;
      case 'reminder':
        return LucideIcons.calendar;
      case 'tip':
        return LucideIcons.lightbulb;
      default:
        return LucideIcons.receipt;
    }
  }
}

class _NotificationIconBubble extends StatelessWidget {
  const _NotificationIconBubble({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: VCareRadius.lgAll,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
