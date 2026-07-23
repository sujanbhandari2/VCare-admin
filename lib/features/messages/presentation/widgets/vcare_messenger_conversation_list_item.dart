import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:intl/intl.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';

/// VCare-styled conversation list row for [MessengerChatShell.userListItemBuilder].
class VcareMessengerConversationListItem extends StatelessWidget {
  const VcareMessengerConversationListItem({
    super.key,
    required this.data,
    required this.vcare,
    this.lastActivityAt,
  });

  final MessengerUserListItemData data;
  final VCareThemeExtension vcare;

  /// Last activity time for conversation rows; drives the relative timestamp.
  final DateTime? lastActivityAt;

  @override
  Widget build(BuildContext context) {
    final preview = data.messagePreview ?? data.subtitle;
    // Prefer the package group flag; also treat multi-member conversation rows
    // as groups so we show the Users icon instead of title initials.
    final isGroupRow = data.useGroupAvatar ||
        (data.isConversationRow && data.groupAvatarUsers.length > 1);
    // peerUsers excludes the current user; include self for total member count.
    final groupMemberCount = data.groupAvatarUsers.length + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vcare.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Match package default: ignore taps while a conversation open is in flight.
        onTap: data.isOpening ? null : data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              VcareMessengerPresenceAvatar(
                displayTitle: data.displayTitle,
                imageUrl: isGroupRow ? null : data.user.avatarUrl,
                isGroup: isGroupRow,
                isOnline: data.user.isOnline,
                showOnlinePresence: data.showOnlinePresence && !isGroupRow,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.displayTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastActivityAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatConversationTimestamp(lastActivityAt!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: VCareColors.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isGroupRow) ...[
                      const SizedBox(height: 2),
                      Text(
                        'GROUP · $groupMemberCount MEMBERS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: vcare.accent,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview.isEmpty
                                ? 'No messages yet — say hi 👋'
                                : preview,
                            style: TextStyle(
                              fontSize: 13,
                              color: vcare.mutedForeground.withValues(
                                alpha: 0.8,
                              ),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (data.isOpening)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (data.hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: VCareColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Relative timestamp for the conversation list:
/// seconds/minutes/hours ago, then "Yesterday", then a short date (e.g. Jul 1).
String _formatConversationTimestamp(DateTime time) {
  final now = DateTime.now();
  final local = time.toLocal();
  final diff = now.difference(local);

  if (!diff.isNegative && diff.inSeconds < 60) {
    final seconds = diff.inSeconds < 1 ? 1 : diff.inSeconds;
    return '$seconds sec';
  }
  if (!diff.isNegative && diff.inMinutes < 60) {
    return '${diff.inMinutes} min';
  }

  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(local.year, local.month, local.day);
  final dayDiff = today.difference(thatDay).inDays;

  if (dayDiff <= 0) {
    final hours = diff.inHours < 1 ? 1 : diff.inHours;
    return '$hours hr';
  }
  if (dayDiff == 1) {
    return 'Yesterday';
  }
  return DateFormat('MMM d').format(local);
}
