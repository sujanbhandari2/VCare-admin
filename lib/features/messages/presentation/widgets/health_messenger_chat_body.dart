import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_media_headers.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_mobile_direct_chat_provider.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_provider.dart';
import 'package:vcare_admin/features/messages/presentation/providers/live_chat_mobile_thread_visible_provider.dart';
import 'package:vcare_admin/features/messages/presentation/theme/vcare_messenger_list_style.dart';
import 'package:vcare_admin/features/messages/presentation/theme/vcare_messenger_thread_theme.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_thread_overrides.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_add_group_members_sheet.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_group_info_sheet.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_start_new_chat_presenter.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_connection_edge_case.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_conversation_list_item.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_inbox_empty_state.dart';
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

  @override
  void initState() {
    super.initState();
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
      unawaited(notifier.ensureAssociatedUsersLoaded());
    });
  }

  @override
  void dispose() {
    // Route may be torn down with the tab; ensure shell inset is restored.
    ref.read(liveChatMobileThreadVisibleProvider.notifier).setVisible(false);
    _composerController.dispose();
    _messagesScrollController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _retryBootstrap() {
    unawaited(() async {
      await ref
          .read(healthMessengerSessionProvider.notifier)
          .recoverConnection(force: true);
      if (!mounted) {
        return;
      }
      final notifier = ref.read(healthMessengerChatProvider.notifier);
      await notifier.bootstrap();
      await notifier.ensureAssociatedUsersLoaded();
    }());
  }

  void _scrollToBottom() {
    // Retries until the mobile thread ListView attaches. A single post-frame
    // animateTo often runs during selectConversation — before Navigator.push —
    // so the open thread would otherwise stay pinned at the top.
    MessengerThreadScroll.scheduleJumpToBottom(
      _messagesScrollController,
      maxAttempts: 60,
      settleFrames: 10,
    );
  }

  Future<void> _handleSend(HealthMessengerChatNotifier notifier) async {
    final chatState = ref.read(healthMessengerChatProvider);
    if (chatState.composerEditDraft != null) {
      final success =
          await notifier.submitComposerEdit(_composerController.text);
      if (success && mounted) {
        _composerController.clear();
      }
      return;
    }

    final success = await notifier.sendTextMessage(_composerController.text);
    if (success && mounted) {
      _composerController.clear();
    }
  }

  Future<void> _handleBeginEditMessage(
    HealthMessengerChatNotifier notifier,
    String messageId,
    String currentText,
  ) async {
    notifier.beginComposerEdit(messageId);
    _composerController.text = currentText;
    _composerController.selection = TextSelection.collapsed(
      offset: currentText.length,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_composerFocusNode.canRequestFocus) {
        _composerFocusNode.requestFocus();
      }
    });
  }

  void _handleCancelComposerEdit(HealthMessengerChatNotifier notifier) {
    notifier.clearComposerEdit();
    _composerController.clear();
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

  /// Auth headers for attachment downloads, scoped to the chat API origin.
  ///
  /// Kept as a method tear-off so the shell's media scope keeps a stable
  /// callback identity across rebuilds.
  Future<Map<String, String>> _resolveMediaHeaders(String url) async {
    final session = ref.read(healthMessengerSessionProvider).session;
    final headers = healthMessengerMediaHeaders(
      mediaUrl: url,
      apiBaseUrl: session?.config.apiBaseUrl ?? '',
      auth: session?.sessionAuth,
    );
    if (kDebugMode) {
      debugPrint('[chat-media] GET $url (auth headers: ${headers.isNotEmpty})');
    }
    return headers;
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

  /// Merges inbox ordering/unread signals with thread content mutations so
  /// reactions, edits, deletes, and presence updates rebuild the shell.
  Listenable? _shellListenable(
    ChatSession session,
    HealthMessengerChatNotifier notifier,
  ) {
    final inbox = _inboxListenable(session);
    return Listenable.merge([
      inbox,
      notifier.shellContentListenable,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      healthMessengerChatProvider.select((state) => state.selectedConversationId),
      (previous, next) {
        if (previous != next) {
          _composerController.clear();
        }
      },
    );

    final chatState = ref.watch(healthMessengerChatProvider);
    ref.watch(
      healthMessengerChatProvider.select((state) => state.associatedUsers.length),
    );
    final session = ref.watch(healthMessengerSessionProvider).session;
    final notifier = ref.read(healthMessengerChatProvider.notifier);
    final vcare = context.vcare;
    final shellListenable = session == null
        ? null
        : _shellListenable(session, notifier);

    if (chatState.bootstrapError != null) {
      return VcareMessengerConnectionEdgeCase(
        error: chatState.bootstrapError,
        onRetry: _retryBootstrap,
      );
    }

    // One loader before the shell can mount. After that, inbox refresh uses the
    // package inline spinner via [isListPaneRefreshing] only — no host overlay.
    if (chatState.showPreSessionConnectingShimmer ||
        session == null ||
        session.sessionAuth == null ||
        shellListenable == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: shellListenable,
          builder: (context, _) {
            // Read live state here instead of the enclosing build's snapshot.
            // While the mobile thread route is pushed, this host build stops
            // running, so a captured snapshot would keep feeding the shell the
            // composer drafts and flags it had when the thread was opened.
            final chatState = ref.read(healthMessengerChatProvider);
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
            final availablePeople = messengerAvailablePeopleExcludingConversations(
              allPeople: notifier.uiUsers,
              conversations: conversations,
              currentUserId: chatState.currentUser?.id,
              currentPlatformUserId: notifier.currentPlatformUserId,
            );
            final hasAvailablePeople = availablePeople.isNotEmpty;
            final openingInFlight =
                (chatState.loadingConversationId?.trim().isNotEmpty ?? false) ||
                (chatState.suggestedPeopleOpeningUserId.trim().isNotEmpty);
            return IgnorePointer(
              ignoring: openingInFlight,
              child: MessengerChatShell(
                currentUserId: chatState.currentUser?.id ?? '',
                currentPlatformUserId: notifier.currentPlatformUserId,
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
                composerEditMessageId: chatState.composerEditDraft?.messageId,
                isSending: chatState.isSending,
                isRecording: _isRecording,
                isListPaneRefreshing: chatState.isConversationListLoading ||
                    chatState.isBootstrapping,
                isConversationLoading:
                    chatState.isSelectedConversationLoading,
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
                mediaCacheHeadersForUrl: _resolveMediaHeaders,
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
                onEditMessage: (messageId, currentText) => _handleBeginEditMessage(
                  notifier,
                  messageId,
                  currentText,
                ),
                onDeleteConversation: notifier.deleteConversation,
                onEditGroupConversation: _handleEditGroup,
                onAddPeopleToGroupConversation: _handleAddPeople,
                onMarkSeen: notifier.markSeen,
                canDeleteMessage: notifier.canDeleteMessage,
                canEditMessage: notifier.canEditMessengerMessage,
                enableReactions: true,
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
                    // Messages finish loading before the route is pushed, so the
                    // shell's auto-scroll often misses the ListView. Re-pin here.
                    _scrollToBottom();
                  }
                  unawaited(() async {
                    if (visible) {
                      // Join first, then mark the thread visible (which clears
                      // unread / marks read). List-only selection must not join.
                      await notifier.joinSelectedConversationRoom();
                    }
                    await session.setThreadVisible(visible);
                  }());
                },
                mobileThreadApplyBottomSafeArea: false,
                searchVisibility: MessengerSearchVisibility.never,
                conversationSearchController:
                    widget.conversationSearchController,
                showStartChatFab: false,
                startNewChatController: widget.startNewChatController,
                startNewChatPresenter: (context, request) {
                  ref
                      .read(healthMessengerMobileDirectChatProvider.notifier)
                      .registerShellOpenDirectChat(request.onOpenDirectChat);
                  return vcarePresentStartNewChat(context, request);
                },
                emptyConversationsMessage:
                    'No conversations yet. Start one from the people list.',
                emptyUsersMessage:
                    'No users yet. Pull to refresh or check your network.',
                showAvailablePeopleOnMobileInbox: true,
                availablePeopleUsers: notifier.uiUsers,
                availablePeopleItemBuilder: (
                  BuildContext context,
                  MessengerAvailablePersonData data,
                ) {
                  return VcareMessengerConversationListItem(
                    data: vcareMessengerListItemDataFromAvailablePerson(data),
                    vcare: vcare,
                  );
                },
                availablePeopleEmptyMessage: '',
                emptyConversationsBuilder: conversations.isEmpty
                    ? (context) => hasAvailablePeople
                        ? const SizedBox.shrink()
                        : const VcareMessengerInboxEmptyState()
                    : null,
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
                    unreadCount: conversationId == null
                        ? 0
                        : (unreadMap[conversationId] ?? 0),
                  );
                },
                userListItemStyle: VcareMessengerListStyle.fromVcareTheme(context),
                userListItemSpacing: 8,
                userListPadding: const EdgeInsets.symmetric(vertical: 4),
                showHeaderComposeButton: false,
                showHeaderEditButton: false,
                showHeaderTitle: false,
                theme: VcareMessengerThreadTheme.fromContext(context),
                threadViewOverrides: vcareMessengerThreadOverrides(
                  context,
                  composerEditDraft: chatState.composerEditDraft,
                  onCancelComposerEdit: () =>
                      _handleCancelComposerEdit(notifier),
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
