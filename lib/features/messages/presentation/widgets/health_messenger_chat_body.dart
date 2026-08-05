import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_provider.dart';
import 'package:vcare_admin/features/messages/presentation/providers/live_chat_mobile_thread_visible_provider.dart';
import 'package:vcare_admin/features/messages/presentation/theme/vcare_messenger_list_style.dart';
import 'package:vcare_admin/features/messages/presentation/theme/vcare_messenger_thread_theme.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_thread_overrides.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_add_group_members_sheet.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_group_info_sheet.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_start_new_chat_presenter.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_conversation_list_item.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_empty_inbox_pane.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Embeds [MessengerChatShell] backed by [HealthMessengerChatNotifier].
class HealthMessengerChatBody extends ConsumerStatefulWidget {
  const HealthMessengerChatBody({
    super.key,
    this.conversationSearchController,
    this.startNewChatController,
  });

  /// When set, filters the conversation list and hides the package search field.
  final TextEditingController? conversationSearchController;

  /// Host-driven entry point for opening direct / group chat pickers.
  final MessengerStartNewChatController? startNewChatController;

  @override
  ConsumerState<HealthMessengerChatBody> createState() =>
      _HealthMessengerChatBodyState();
}

class _HealthMessengerChatBodyState
    extends ConsumerState<HealthMessengerChatBody> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();
  bool _isRecording = false;
  bool _bootstrapStarted = false;
  late final LiveChatMobileThreadVisible _mobileThreadVisibleNotifier;

  @override
  void initState() {
    super.initState();
    _mobileThreadVisibleNotifier =
        ref.read(liveChatMobileThreadVisibleProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bootstrapStarted) {
        return;
      }
      _bootstrapStarted = true;
      final notifier = ref.read(healthMessengerChatProvider.notifier);
      notifier.onRequestScrollToBottom = _scrollToBottom;
      notifier.onUserMessage = (message) {
        if (!mounted) {
          return;
        }
        context.showVcareToast(
          title: message,
          variant: VcareToastVariant.info,
        );
      };
      unawaited(notifier.bootstrap());
    });
  }

  @override
  void dispose() {
    // Route may be torn down with the tab; ensure shell inset is restored.
    _mobileThreadVisibleNotifier.setVisible(false);
    _composerController.dispose();
    _messagesScrollController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messagesScrollController.hasClients) {
        return;
      }
      _messagesScrollController.animateTo(
        _messagesScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend(HealthMessengerChatNotifier notifier) async {
    final success = await notifier.sendTextMessage(_composerController.text);
    if (success && mounted) {
      _composerController.clear();
    }
  }

  Future<void> _handleEditGroup(MessengerConversation conversation) async {
    if (!mounted) {
      return;
    }
    await HealthMessengerGroupInfoSheet.show(
      context,
      conversation: conversation,
    );
  }

  Future<void> _handleAddPeople(MessengerConversation conversation) async {
    if (!mounted) {
      return;
    }
    await HealthMessengerAddGroupMembersSheet.show(
      context,
      conversation: conversation,
    );
  }

  /// Returns inbox listenables when bootstrap completed; otherwise null.
  Listenable? _inboxListenable(ChatSession session) {
    try {
      final inbox = session.inbox;
      return Listenable.merge([
        inbox.unreadByConversation,
        inbox.conversationOrder,
      ]);
    } on StateError {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(healthMessengerChatProvider);
    final session = ref.watch(healthMessengerSessionProvider).session;
    final notifier = ref.read(healthMessengerChatProvider.notifier);
    final vcare = context.vcare;
    final inboxListenable =
        session == null ? null : _inboxListenable(session);

    if (chatState.bootstrapError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            chatState.bootstrapError.toString(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // One loader before the shell can mount. After that, inbox refresh uses the
    // package inline spinner via [isListPaneRefreshing] only — no host overlay.
    if (chatState.showPreSessionConnectingShimmer ||
        session == null ||
        session.sessionAuth == null ||
        inboxListenable == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: inboxListenable,
          builder: (context, _) {
            final inbox = session.inbox;
            final unreadMap = inbox.unreadByConversation.value;
            final orderSnapshot = inbox.conversationOrder.value;
            final conversations = notifier.messengerConversationsFor(
              unreadMap: unreadMap,
              orderSnapshot: orderSnapshot,
            );
            final lastActivityByConversationId = <String, DateTime>{
              for (final conversation in conversations)
                conversation.id: conversation.effectiveActivityAt,
            };
            final openingInFlight =
                (chatState.loadingConversationId?.trim().isNotEmpty ?? false) ||
                (chatState.suggestedPeopleOpeningUserId.trim().isNotEmpty);
            return IgnorePointer(
              ignoring: openingInFlight,
              child: MessengerChatShell(
                currentUserId: chatState.currentUser?.id ?? '',
                currentUserName: chatState.currentUser?.displayName ?? 'User',
                conversations: conversations,
                users: notifier.uiUsers,
                selectedConversationId: chatState.selectedConversationId,
                messages: notifier.activeMessages,
                composerController: _composerController,
                messagesScrollController: _messagesScrollController,
                composerFocusNode: _composerFocusNode,
                composerReplyDraft: chatState.composerReplyDraft,
                onComposerReplyDraftChanged: notifier.updateComposerReplyDraft,
                isSending: chatState.isSending,
                isRecording: _isRecording,
                isListPaneRefreshing: chatState.isConversationListLoading ||
                    chatState.isBootstrapping,
                isConversationLoading:
                    chatState.loadingConversationId ==
                    chatState.selectedConversationId,
                loadingConversationId: chatState.loadingConversationId,
                onRefresh: () => notifier.refreshAll(),
                onLogout: () => unawaited(notifier.logoutAndClear()),
                onSelectConversation: notifier.selectConversation,
                onOpenDirectChat: notifier.openDirectChat,
                onCreateGroupRequested: notifier.createGroupChatFromRequest,
                isCreatingGroup: chatState.isCreatingGroup,
                groupNameInputBehavior: MessengerGroupNameInputBehavior.required,
                onSend: () => unawaited(_handleSend(notifier)),
                // Empty host fallbacks — package orchestrator handles pick when
                // enablePackageMediaSending + media* are set (VCare Care Team parity).
                onPickImage: () {},
                onPickAudio: () {},
                onPickCamera: () {},
                onPickDocument: () {},
                onToggleRecording: () {
                  setState(() => _isRecording = !_isRecording);
                },
                enablePackageMediaSending: true,
                mediaChatClient: session.client,
                mediaChatAuth: session.sessionAuth,
                mediaSenderId: chatState.currentUser?.id,
                onMediaSendProgress: (pendingMessageId, progress) {
                  notifier.setMediaUploading(true);
                },
                onMediaSendError: (pendingMessageId, error) {
                  notifier.setMediaUploading(false);
                },
                onMediaMessageSentForConversation: (conversationId, message) {
                  notifier.setMediaUploading(false);
                  notifier.upsertMediaMessage(conversationId, message);
                  _scrollToBottom();
                },
                onReact: notifier.reactToMessage,
                onRemoveReaction: notifier.removeReactionFromMessage,
                onDelete: notifier.deleteMessage,
                onEditMessage: notifier.editMessage,
                onDeleteConversation: notifier.deleteConversation,
                onEditGroupConversation: _handleEditGroup,
                onAddPeopleToGroupConversation: _handleAddPeople,
                onMarkSeen: notifier.markSeen,
                canDeleteMessage: notifier.canDeleteMessage,
                canEditMessage: notifier.canEditMessengerMessage,
                remoteTypingUsers: notifier.remoteTypingUsers,
                onTypingStart: notifier.onTypingStart,
                onTypingStop: notifier.onTypingStop,
                prepareOutgoingConversation: notifier.prepareOutgoingConversation,
                onMobileThreadClosed: (conversationId) {
                  ref
                      .read(liveChatMobileThreadVisibleProvider.notifier)
                      .setVisible(false);
                  unawaited(notifier.onMobileThreadClosed(conversationId));
                },
                onThreadVisibilityChanged: (visible) {
                  // Layout inset: only flip on when the thread opens. Closing is
                  // handled in [onMobileThreadClosed] so list-pane rebuilds that
                  // briefly report hidden do not restore the shell gap.
                  if (visible) {
                    ref
                        .read(liveChatMobileThreadVisibleProvider.notifier)
                        .setVisible(true);
                  }
                  unawaited(session.setThreadVisible(visible));
                },
                mobileThreadApplyBottomSafeArea: false,
                searchVisibility: MessengerSearchVisibility.never,
                conversationSearchController:
                    widget.conversationSearchController,
                showStartChatFab: false,
                startNewChatController: widget.startNewChatController,
                startNewChatPresenter: vcarePresentStartNewChat,
                emptyConversationsMessage:
                    'No conversations yet. Start one from the people list.',
                emptyUsersMessage:
                    'No users yet. Pull to refresh or check your network.',
                userListItemBuilder: (
                  BuildContext context,
                  MessengerUserListItemData data,
                ) {
                  final conversationId = data.conversationId;
                  return VcareMessengerConversationListItem(
                    data: data,
                    vcare: vcare,
                    lastActivityAt: conversationId == null
                        ? null
                        : lastActivityByConversationId[conversationId],
                  );
                },
                userListItemStyle: VcareMessengerListStyle.fromVcareTheme(context),
                userListItemSpacing: 8,
                userListPadding: const EdgeInsets.symmetric(vertical: 4),
                showHeaderComposeButton: false,
                showHeaderEditButton: false,
                showHeaderTitle: false,
                theme: VcareMessengerThreadTheme.fromContext(context),
                threadViewOverrides: vcareMessengerThreadOverrides(context),
                emptyInboxBuilder: (context) => VcareMessengerEmptyInboxPane(
                  isRefreshing: chatState.isConversationListLoading ||
                      chatState.isBootstrapping,
                  onRefresh: () => notifier.refreshAll(),
                ),
              ),
            );
          },
        ),
        if (chatState.showFullScreenLoader)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
