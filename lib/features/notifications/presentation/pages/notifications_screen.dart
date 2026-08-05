import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/notifications/domain/entities/notification_item.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/notification_inbox_state_provider.dart';
import 'package:vcare_admin/features/notifications/presentation/widgets/notification_inbox_tile.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: Re-enable when notifications API is available.
      // ref.read(notificationInboxStateProvider.notifier).fetchInbox();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(notificationInboxStateProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Re-enable when notifications API is available.
          // await ref.read(notificationInboxStateProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverVcarePageHeader(
              title: 'Notifications',
              subtitle: 'Messages, reminders, tips, and billing updates',
              showBack: true,
              onBack: () => context.pop(),
            ),
            if (inboxState.fetching && inboxState.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (inboxState.hasError && inboxState.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: VcareErrorStatePanel(
                  icon: LucideIcons.alertCircle,
                  title: 'Could not load notifications',
                  message: inboxState.error,
                  actionLabel: context.appLocalization.retry,
                  onAction: () {
                    // TODO: Re-enable when notifications API is available.
                    // ref.read(notificationInboxStateProvider.notifier).fetchInbox();
                  },
                ),
              )
            else if (inboxState.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _NotificationsMessagePanel(
                  icon: LucideIcons.bellOff,
                  title: 'No notifications yet',
                  subtitle: 'Updates from your care team will appear here.',
                ),
              )
            else
              SliverPadding(
                padding: context.mobileShellScrollPadding,
                sliver: SliverList.separated(
                  itemCount: inboxState.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notification = inboxState.items[index];
                    return NotificationInboxTile(
                      notification: notification,
                      onTap: () => _onNotificationTap(notification),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onNotificationTap(NotificationItem notification) async {
    if (!notification.read) {
      await ref
          .read(notificationInboxStateProvider.notifier)
          .markAsRead(id: notification.id);
    }

    if (!mounted) return;

    switch (notification.type) {
      case 'message':
        context.pushNamed(AppRouter.messages.toPathName);
      case 'tip':
        context.go(AppRouter.profile);
      default:
        context.pushNamed(AppRouter.requests.toPathName);
    }
  }
}

class _NotificationsMessagePanel extends StatelessWidget {
  const _NotificationsMessagePanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: context.vcare.mutedForeground),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.vcare.mutedForeground),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
