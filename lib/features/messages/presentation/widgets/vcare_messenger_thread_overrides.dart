import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_state.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_role_badge.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_thread_composer.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

enum _ThreadOverflowAction {
  editGroup,
  addPeople,
  deleteChat,
}

/// Builds [MessengerThreadViewOverrides] for VCare Live Chat conversation UI.
MessengerThreadViewOverrides vcareMessengerThreadOverrides(
  BuildContext context, {
  MessengerComposerEditDraft? composerEditDraft,
  VoidCallback? onCancelComposerEdit,
}) {
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
    composerBuilder: (context, data) => VcareMessengerThreadComposer(
      data: data,
      editDraft: composerEditDraft,
      onCancelEditDraft: onCancelComposerEdit,
    ),
  );
}

Widget _buildHeader(BuildContext context, MessengerThreadHeaderData data) {
  final conversation = data.conversation;
  if (conversation == null) {
    return const SizedBox.shrink();
  }

  final overflow = _buildOverflowAction(context, data, conversation);
  final roleLabel = _directConversationRoleLabel(conversation);
  final headerAvatarUrl = _conversationHeaderAvatarUrl(conversation);

  return VcarePinnedHeaderChrome(
    child: VcarePageHeader(
      title: conversation.title,
      titleMaxLines: 2,
      titleStyle: VcarePageHeaderLayout.titleTextStyle(context).copyWith(
        fontSize: 16,
        height: 1.2,
        letterSpacing: -0.1,
      ),
      titleLeading: VcareMessengerPresenceAvatar(
        displayTitle: conversation.title,
        imageUrl: headerAvatarUrl,
        isGroup: conversation.isGroup,
        isOnline: conversation.isOnline ?? false,
        showOnlinePresence: !conversation.isGroup,
        size: 40,
        borderRadius: 14,
      ),
      subtitle: conversation.isGroup ? 'Shared care-team conversation' : null,
      subtitleWidget: roleLabel.isEmpty
          ? null
          : VcareMessengerRoleBadge(roleLabel: roleLabel, compact: true),
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
    ),
  );
}

/// Direct chats only show a photo when [MessengerConversation.avatarUrl] (or a
/// peer avatar) is present; groups keep the shared Users icon.
String? _conversationHeaderAvatarUrl(MessengerConversation conversation) {
  if (conversation.isGroup) {
    return null;
  }
  final direct = conversation.avatarUrl?.trim();
  if (direct != null && direct.isNotEmpty) {
    return direct;
  }
  for (final peer in conversation.peerUsers) {
    final peerAvatar = peer.avatarUrl?.trim();
    if (peerAvatar != null && peerAvatar.isNotEmpty) {
      return peerAvatar;
    }
  }
  return null;
}

String _directConversationRoleLabel(MessengerConversation conversation) {
  if (conversation.isGroup) {
    return '';
  }
  for (final user in conversation.peerUsers) {
    final role = user.roleLabel.trim();
    if (role.isNotEmpty) {
      return role;
    }
  }
  return '';
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
    icon: Icon(LucideIcons.moreVertical, size: 22, color: VCareColors.foreground),
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
