import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:intl/intl.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_role_badge.dart';

/// Maps an available-person row to the shared list card payload.
MessengerUserListItemData vcareMessengerListItemDataFromAvailablePerson(
  MessengerAvailablePersonData data,
) {
  final user = data.user;
  return MessengerUserListItemData(
    user: user,
    isSelected: false,
    hasUnread: false,
    isOpening: data.isOpening,
    messagePreview: null,
    onTap: data.onTap,
    showOnlinePresence: false,
    displayTitle: conversationListItemDisplayName(user.username),
    subtitle: '',
    roleLabel: user.roleLabel.trim(),
  );
}

/// VCare-styled conversation list row for [MessengerChatShell.userListItemBuilder].
class VcareMessengerConversationListItem extends StatelessWidget {
  const VcareMessengerConversationListItem({
    super.key,
    required this.data,
    required this.vcare,
    this.lastActivityAt,
    this.unreadCount = 0,
  });

  final MessengerUserListItemData data;
  final VCareThemeExtension vcare;

  /// Last activity time for conversation rows; drives the relative timestamp.
  final DateTime? lastActivityAt;

  /// Unread message count for conversation rows (0 hides the badge).
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final preview = data.messagePreview ?? data.subtitle;
    // Prefer the package group flag; also treat multi-member conversation rows
    // as groups so we show the Users icon instead of title initials.
    final isGroupRow = data.useGroupAvatar ||
        (data.isConversationRow && data.groupAvatarUsers.length > 1);
    // peerUsers excludes the current user; include self for total member count.
    final groupMemberCount = data.groupAvatarUsers.length + 1;
    final roleLabel = isGroupRow
        ? ''
        : (data.roleLabel.trim().isNotEmpty
            ? data.roleLabel.trim()
            : data.user.roleLabel.trim());

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
              if (data.showOnlinePresence && !isGroupRow)
                VcareMessengerPresenceAvatar(
                  displayTitle: data.displayTitle,
                  // Active conversation rows: photo only when a URL is available.
                  imageUrl: _nonEmptyAvatarUrl(data.user.avatarUrl),
                  isGroup: false,
                  isOnline: data.user.isOnline,
                )
              else
                VcareMessengerAvatar(
                  displayTitle: data.displayTitle,
                  imageUrl: isGroupRow
                      ? null
                      : _nonEmptyAvatarUrl(data.user.avatarUrl),
                  isGroup: isGroupRow,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
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
                              if (roleLabel.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                VcareMessengerRoleBadge(
                                  roleLabel: roleLabel,
                                  compact: true,
                                ),
                              ],
                            ],
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
                              fontWeight: data.hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: data.hasUnread
                                  ? VCareColors.foreground
                                  : vcare.mutedForeground.withValues(
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
                        else if (data.hasUnread && unreadCount > 0)
                          _UnreadCountBadge(count: unreadCount),
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

class _UnreadCountBadge extends StatelessWidget {
  const _UnreadCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    final minWidth = count > 9 ? 28.0 : 24.0;

    return Container(
      margin: const EdgeInsets.only(left: 8),
      constraints: BoxConstraints(minWidth: minWidth, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: VCareColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

String? _nonEmptyAvatarUrl(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
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
