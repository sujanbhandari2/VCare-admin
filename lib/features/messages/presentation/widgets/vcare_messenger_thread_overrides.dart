import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_thread_composer.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

enum _ThreadOverflowAction {
  editGroup,
  addPeople,
  deleteChat,
}

/// Builds [MessengerThreadViewOverrides] for VCare Live Chat conversation UI.
MessengerThreadViewOverrides vcareMessengerThreadOverrides(BuildContext context) {
  return MessengerThreadViewOverrides(
    headerBuilder: _buildHeader,
    messageContentBuilders: MessengerMessageContentBuilders(
      textBuilder: _buildTextContent,
      imageBuilder: _buildDefaultContent,
      voiceBuilder: _buildDefaultContent,
      fileBuilder: _buildDefaultContent,
      videoBuilder: _buildDefaultContent,
      mixedAttachmentsBuilder: _buildDefaultContent,
      deletedBuilder: _buildDeletedContent,
      uploadingBuilder: _buildUploadingContent,
    ),
    composerBuilder: (context, data) => VcareMessengerThreadComposer(data: data),
  );
}

Widget _buildHeader(BuildContext context, MessengerThreadHeaderData data) {
  final conversation = data.conversation;
  if (conversation == null) {
    return const SizedBox.shrink();
  }

  final overflow = _buildOverflowAction(context, data, conversation);
  final avatarUrl = conversation.avatarUrl?.trim();
  final showAvatar = !conversation.isGroup &&
      avatarUrl != null &&
      avatarUrl.isNotEmpty;

  return VcareStickyPageHeader(
    title: conversation.title,
    subtitle: conversation.isGroup ? 'Shared care-team conversation' : null,
    leading: showAvatar
        ? VcareMessengerAvatar(
            displayTitle: conversation.title,
            imageUrl: avatarUrl,
            size: 40,
            borderRadius: 12,
          )
        : null,
    showBack: data.isMobile,
    onBack: data.onBack,
    showBell: conversation.isGroup && data.onEditGroupConversation != null,
    onBellTap: conversation.isGroup && data.onEditGroupConversation != null
        ? () => unawaited(
              Future<void>.sync(
                () => data.onEditGroupConversation!(conversation),
              ),
            )
        : null,
    action: overflow,
  );
}

Widget? _buildOverflowAction(
  BuildContext context,
  MessengerThreadHeaderData data,
  MessengerConversation conversation,
) {
  final items = <PopupMenuEntry<_ThreadOverflowAction>>[];
  if (conversation.isGroup && data.onEditGroupConversation != null) {
    items.add(
      const PopupMenuItem(
        value: _ThreadOverflowAction.editGroup,
        child: Text('Edit'),
      ),
    );
  }
  if (conversation.isGroup && data.onAddPeopleToGroupConversation != null) {
    items.add(
      const PopupMenuItem(
        value: _ThreadOverflowAction.addPeople,
        child: Text('Add people'),
      ),
    );
  }
  if (data.onDeleteConversation != null) {
    items.add(
      PopupMenuItem(
        value: _ThreadOverflowAction.deleteChat,
        child: Text(
          'Delete chat',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  if (items.isEmpty) {
    return null;
  }

  return PopupMenuButton<_ThreadOverflowAction>(
    icon: const Icon(LucideIcons.moreVertical, size: 22),
    itemBuilder: (_) => items,
    onSelected: (action) {
      unawaited(_onOverflowSelected(context, data, conversation, action));
    },
  );
}

Future<void> _onOverflowSelected(
  BuildContext context,
  MessengerThreadHeaderData data,
  MessengerConversation conversation,
  _ThreadOverflowAction action,
) async {
  switch (action) {
    case _ThreadOverflowAction.editGroup:
      await Future<void>.sync(
        () => data.onEditGroupConversation?.call(conversation),
      );
    case _ThreadOverflowAction.addPeople:
      await Future<void>.sync(
        () => data.onAddPeopleToGroupConversation?.call(conversation),
      );
    case _ThreadOverflowAction.deleteChat:
      await _confirmAndDeleteConversation(context, data, conversation);
  }
}

Future<void> _confirmAndDeleteConversation(
  BuildContext context,
  MessengerThreadHeaderData data,
  MessengerConversation conversation,
) async {
  final delete = data.onDeleteConversation;
  if (delete == null) {
    return;
  }
  final rawTitle = conversation.title.trim();
  final label = rawTitle.isEmpty ? 'this chat' : rawTitle;
  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) => _VcareDeleteChatDialog(
      conversationTitle: label,
      onDeleteConfirmed: () async {
        await Future<void>.sync(() => delete(conversation));
      },
    ),
  );
}

class _VcareDeleteChatDialog extends StatefulWidget {
  const _VcareDeleteChatDialog({
    required this.conversationTitle,
    required this.onDeleteConfirmed,
  });

  final String conversationTitle;
  final Future<void> Function() onDeleteConfirmed;

  @override
  State<_VcareDeleteChatDialog> createState() => _VcareDeleteChatDialogState();
}

class _VcareDeleteChatDialogState extends State<_VcareDeleteChatDialog> {
  bool _deleting = false;

  Future<void> _onDeletePressed() async {
    if (_deleting) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await widget.onDeleteConfirmed();
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_deleting,
      child: AlertDialog(
        title: const Text('Delete chat'),
        content: Text(
          'Delete ${widget.conversationTitle}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: _deleting
                ? null
                : () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: VCareColors.destructive,
            ),
            onPressed: _deleting ? null : () => unawaited(_onDeletePressed()),
            child: _deleting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

Widget _buildTextContent(
  BuildContext context,
  MessengerMessageContentData data,
) {
  return Text(
    data.message.content,
    style: TextStyle(
      fontSize: 14,
      height: 1.4,
      color: data.isMine ? Colors.white : Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w400,
    ),
  );
}

Widget _buildDefaultContent(
  BuildContext context,
  MessengerMessageContentData data,
) {
  return MessengerDefaultMessageContent(
    message: data.message,
    textColor: data.textColor,
    mutedColor: data.mutedColor,
    attachmentCaptionStyle: data.attachmentCaptionStyle,
    packageDialogTheme: data.packageDialogTheme,
  );
}

Widget _buildDeletedContent(
  BuildContext context,
  MessengerMessageContentData data,
) {
  return Text(
    'Message deleted',
    style: TextStyle(
      fontSize: 14,
      color: data.textColor.withValues(alpha: 0.85),
      fontStyle: FontStyle.italic,
    ),
  );
}

Widget _buildUploadingContent(
  BuildContext context,
  MessengerMessageContentData data,
) {
  return Text(
    'Uploading...',
    style: TextStyle(
      fontSize: 14,
      color: data.textColor.withValues(alpha: 0.9),
      fontWeight: FontWeight.w600,
    ),
  );
}
