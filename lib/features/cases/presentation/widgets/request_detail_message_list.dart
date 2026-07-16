import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/utils/request_attachments.dart';
import 'package:vcare_admin/features/cases/utils/request_chat_date.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';

class RequestDetailMessageList extends StatelessWidget {
  const RequestDetailMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.onEditMessage,
    required this.onDeleteMessage,
  });

  final List<RequestMessage> messages;
  final ScrollController scrollController;
  final void Function(String id, String body) onEditMessage;
  final void Function(String id) onDeleteMessage;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hi 👋',
          style: TextStyle(color: context.vcare.mutedForeground, fontSize: 14),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (var index = 0; index < messages.length; index++) ...[
                  if (_showDateSeparator(index))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _DateSeparator(
                        label: formatRequestChatDateSeparator(
                          messages[index].createdAt,
                        ),
                      ),
                    ),
                  _MessageRow(
                    message: messages[index],
                    onEdit: messages[index].body.isNotEmpty
                        ? () => onEditMessage(
                            messages[index].id,
                            messages[index].body,
                          )
                        : null,
                    onDelete: () => onDeleteMessage(messages[index].id),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _showDateSeparator(int index) {
    if (index == 0) return true;
    final previous = messages[index - 1];
    final current = messages[index];
    return !requestSameDay(previous.createdAt, current.createdAt);
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: vcare.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: vcare.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    this.onEdit,
    required this.onDelete,
  });

  final RequestMessage message;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isMe = message.sender == 'me';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [VCareColors.accent, VCareColors.primary],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.shieldCheck,
              size: 14,
              color: VCareColors.primaryForeground,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (isMe) _MessageActionsMenu(onEdit: onEdit, onDelete: onDelete),
        Flexible(
          child: _MessageBubble(message: message, isMe: isMe),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final RequestMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final time = DateFormat('MMM d, h:mm a').format(message.createdAt);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? VCareColors.primary : vcare.muted,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (message.body.isNotEmpty)
            Text(
              message.body,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isMe
                    ? VCareColors.primaryForeground
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          for (final attachment in message.attachments ?? const [])
            Padding(
              padding: EdgeInsets.only(top: message.body.isNotEmpty ? 8 : 0),
              child: _AttachmentChip(attachment: attachment, isMe: isMe),
            ),
          const SizedBox(height: 4),
          Text(
            time,
            textAlign: isMe ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 10,
              color:
                  (isMe ? VCareColors.primaryForeground : vcare.mutedForeground)
                      .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.attachment, required this.isMe});

  final RequestAttachment attachment;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final audio = isRequestAudioAttachment(attachment.dataUrl, attachment.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? VCareColors.primaryForeground.withValues(alpha: 0.15)
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            audio ? LucideIcons.mic : LucideIcons.paperclip,
            size: 12,
            color: isMe ? VCareColors.primaryForeground : vcare.mutedForeground,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isMe
                    ? VCareColors.primaryForeground
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageActionsMenu extends StatelessWidget {
  const _MessageActionsMenu({this.onEdit, required this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(
        LucideIcons.moreHorizontal,
        size: 16,
        color: context.vcare.mutedForeground.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(-8, -40),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit', style: TextStyle(fontSize: 13)),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(fontSize: 13, color: VCareColors.destructive),
          ),
        ),
      ],
    );
  }
}
