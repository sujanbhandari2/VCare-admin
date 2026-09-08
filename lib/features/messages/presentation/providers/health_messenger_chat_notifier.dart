import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health_messenger_ui/lib/health_messenger_push.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vcare_admin/features/messages/health_messenger/coalesce_in_flight.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_bootstrap_config.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_connection_recovery.dart';
import 'package:vcare_admin/features/messages/health_messenger/mappers/associated_user_messenger_mapper.dart';
import 'package:vcare_admin/features/messages/health_messenger/mappers/health_messenger_mappers.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_state.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_provider.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';
import 'package:vcare_admin/features/users/presentation/providers/associated_users_repository_provider.dart';

part 'health_messenger_chat_notifier.g.dart';

@riverpod
class HealthMessengerChatNotifier extends _$HealthMessengerChatNotifier {
  static const String _draftDirectPrefix = '__pending_direct__:';

  /// Upper bound for a conversation open. A hung fetch must surface an error
  /// instead of leaving [HealthMessengerChatState.loadingConversationId] set,
  /// which the thread renders as an endless loading placeholder.
  static const Duration _loadMessagesTimeout = Duration(seconds: 20);

  /// Socket room join / leave are best-effort; never block a thread open on them.
  static const Duration _socketRoomTimeout = Duration(seconds: 8);

  /// Incremented per conversation open (and on close) so a slow in-flight open
  /// cannot apply its result over a newer selection.
  int _selectRequestId = 0;

  StreamSubscription<ChatSocketEvent>? _socketSubscription;
  StreamSubscription<MessengerPushEvent>? _pushEventsSubscription;
  VoidCallback? _remotePresenceListener;
  Map<String, bool> _remotePresenceByUserId = const {};
  RemotePresenceStore? _remotePresenceStore;
  final ValueNotifier<int> _shellContentRevision = ValueNotifier<int>(0);
  final Map<String, Map<String, Timer>> _typingExpiryTimers = {};
  Timer? _slowConversationHintTimer;
  ChatSession? _attachedSession;
  Future<void>? _bootstrapFuture;

  /// Receipts that arrived before the target message was in local state.
  final Map<String, List<DeliveredReceipt>> _pendingDeliveredByMessageId = {};
  final Map<String, List<ReadReceipt>> _pendingReadByMessageId = {};

  VoidCallback? onRequestScrollToBottom;
  void Function(String message)? onUserMessage;

  /// Drives [AnimatedBuilder] rebuilds for thread mutations not tied to inbox.
  Listenable get shellContentListenable => _shellContentRevision;

  ChatSession? get _session => ref.read(healthMessengerSessionProvider).session;

  ChatClient? get _client => _session?.client;

  ChatAuth? get _sessionAuth => _session?.sessionAuth;

  MessengerHostActions? get _hostActions {
    final client = _client;
    if (client == null) {
      return null;
    }
    return MessengerHostActions(client: client);
  }

  HealthMessengerMappers get _mappers => HealthMessengerMappers(
    currentUserId: state.currentUser?.id ?? '',
    mediaBaseUrl: _session?.config.apiBaseUrl.trim() ?? '',
    users: state.users,
    associatedUsers: state.associatedUsers,
  );

  @override
  HealthMessengerChatState build() {
    ref.onDispose(_dispose);
    ref.listen(healthMessengerSessionProvider, (previous, next) {
      if (!next.isReady || next.session == null) {
        return;
      }
      if (_bootstrapFuture != null || state.isBootstrapping) {
        return;
      }
      if (identical(_attachedSession, next.session) &&
          state.bootstrapError == null) {
        return;
      }
      // Same ChatSession with flag-only updates (isBootstrapping, push)
      // must not re-enter bootstrap. Main wrapper already starts the
      // session, so opening Messages used to stack-overflow here.
      if (identical(previous?.session, next.session) &&
          (previous?.isReady ?? false) &&
          state.bootstrapError == null) {
        return;
      }
      unawaited(bootstrap());
    });
    return const HealthMessengerChatState();
  }

  Future<void> bootstrap() {
    return coalesceInFlightFuture(
      read: () => _bootstrapFuture,
      write: (next) => _bootstrapFuture = next,
      start: _bootstrapInternal,
    );
  }

  Future<void> _bootstrapInternal() async {
    final alreadyFailed = state.bootstrapError != null;
    if (identical(_attachedSession, _session) &&
        _session?.sessionAuth != null &&
        !alreadyFailed) {
      if (!state.isSocketConnected) {
        await ensureSocketConnected();
      }
      return;
    }

    state = state.copyWith(
      isBootstrapping: true,
      initialBootstrapLoad: true,
      clearBootstrapError: true,
    );

    try {
      await ref.read(healthMessengerSessionProvider.notifier).ensureStarted();
      if (!ref.mounted) {
        return;
      }

      final sessionState = ref.read(healthMessengerSessionProvider);
      final activeSession = sessionState.session;
      if (activeSession == null || sessionState.bootstrapConfig == null) {
        final error =
            sessionState.bootstrapError ??
            Exception('Chat session is not available.');
        state = state.copyWith(
          bootstrapError: error,
          isBootstrapping: false,
          initialBootstrapLoad: false,
        );
        if (!alreadyFailed) {
          _snack('Chat could not start.');
        }
        return;
      }

      await _attachToSession(activeSession);
      if (!ref.mounted) {
        return;
      }

      // Hand off to package list spinner without a blank frame between attach
      // and refresh (host no longer stacks a second overlay).
      state = state.copyWith(
        isBootstrapping: false,
        isConversationListLoading: true,
      );
      // Do not auto-select/join the first conversation. On mobile that joined the
      // room while the list was showing and caused new messages to be marked read.
      await refreshAll(selectFirstConversation: false);
    } catch (error, stackTrace) {
      _log(
        'Bootstrap failed',
        data: {'error': error.toString(), 'stackTrace': stackTrace.toString()},
      );
      state = state.copyWith(
        bootstrapError: error,
        isBootstrapping: false,
        initialBootstrapLoad: false,
        isSocketConnected: false,
      );
      if (!alreadyFailed) {
        _snack('Chat could not start. Check logs and configuration.');
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          isBootstrapping: false,
          initialBootstrapLoad: false,
        );
      }
    }
  }

  Future<void> _attachToSession(ChatSession activeSession) async {
    await detachFromSession();

    final registeredUser = activeSession.currentUser;
    if (registeredUser == null) {
      throw Exception('Chat session has no registered user.');
    }

    _listenToSocketEvents(activeSession.client);
    await _pushEventsSubscription?.cancel();
    _pushEventsSubscription = ref
        .read(healthMessengerSessionProvider.notifier)
        .pushEvents
        .listen(_onMessengerPushEvent);

    state = HealthMessengerChatState(
      currentUser: registeredUser,
      isSocketConnected: activeSession.isSocketConnected,
    );
    _attachedSession = activeSession;
    _bindRemotePresenceListener(activeSession);
  }

  Future<void> detachFromSession() async {
    _cancelSlowConversationHint();
    _cancelAllTypingExpiryTimers();
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _pushEventsSubscription?.cancel();
    _pushEventsSubscription = null;
    _unbindRemotePresenceListener();
    _pendingDeliveredByMessageId.clear();
    _pendingReadByMessageId.clear();
    _attachedSession = null;
  }

  Future<void> refreshAll({bool selectFirstConversation = false}) async {
    final client = _client;
    final auth = _sessionAuth;
    if (client == null || auth == null) {
      return;
    }

    state = state.copyWith(
      isRefreshing: true,
      isConversationListLoading: true,
      isSuggestedUsersLoading: true,
    );

    try {
      final current = state.currentUser;
      final chatUserId = current?.id.trim();
      if (chatUserId == null || chatUserId.isEmpty) {
        return;
      }

      final associatedUsersFuture = _loadAssociatedUsers();
      final usersFuture = client.getUsers(auth);
      final conversations = await client.getConversations(
        auth,
        forUserId: chatUserId,
      );

      if (!ref.mounted) {
        return;
      }

      var selectedConversationId = state.selectedConversationId;
      if (selectedConversationId != null &&
          !isDraftConversationId(selectedConversationId) &&
          !conversations.any(
            (conversation) => conversation.id == selectedConversationId,
          )) {
        selectedConversationId = null;
      }

      state = state.copyWith(
        conversations: conversations,
        selectedConversationId: selectedConversationId,
        clearSelectedConversationId: selectedConversationId == null,
        // A conversation that disappeared server-side can have an open load;
        // dropping the selection must drop that loading id with it.
        clearLoadingConversationId: selectedConversationId == null,
        isConversationListLoading: false,
        initialBootstrapLoad: false,
      );
      _session?.inbox.seedFromConversations(conversations);

      if (selectedConversationId != null &&
          !isDraftConversationId(selectedConversationId)) {
        await _loadMessages(selectedConversationId);
      } else if (selectFirstConversation && conversations.isNotEmpty) {
        await selectConversation(conversations.first.id, tryReconnect: false);
      }

      final users = await usersFuture;
      await associatedUsersFuture;

      if (!ref.mounted) {
        return;
      }

      TenantUser? selectedCurrentUser;
      for (final user in users) {
        if (user.id == state.currentUser?.id) {
          selectedCurrentUser = user;
          break;
        }
      }

      state = state.copyWith(
        users: users,
        currentUser:
            selectedCurrentUser ??
            state.currentUser ??
            (users.isNotEmpty ? users.first : null),
        isSuggestedUsersLoading: false,
      );
      _notifyShellContentChanged();

      if (!state.isSocketConnected) {
        await ensureSocketConnected();
      }

      _syncPresenceFromStore();
    } catch (error, stackTrace) {
      _log(
        'Refresh failed',
        data: {'error': error.toString(), 'stackTrace': stackTrace.toString()},
      );
      _snack('Refresh failed.');
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          isRefreshing: false,
          isConversationListLoading: false,
          isSuggestedUsersLoading: false,
        );
      }
    }
  }

  Future<void> ensureAssociatedUsersLoaded() async {
    if (state.associatedUsers.isNotEmpty || state.isSuggestedUsersLoading) {
      return;
    }

    state = state.copyWith(isSuggestedUsersLoading: true);
    try {
      await _loadAssociatedUsers();
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isSuggestedUsersLoading: false);
      }
    }
  }

  Future<void> _loadAssociatedUsers() async {
    final repository = ref.read(associatedUsersRepositoryProvider);
    final collected = <AssociatedUser>[];
    var page = 1;
    var hasNext = true;

    while (hasNext) {
      final result = await repository.fetchAssociatedUsers(page: page);
      if (!ref.mounted) {
        return;
      }

      var fetchedPage = false;
      result.when(
        success: (associatedPage) {
          collected.addAll(associatedPage.users);
          hasNext = associatedPage.pagination.hasNext;
          page = associatedPage.pagination.page + 1;
          fetchedPage = true;
        },
        failure: (error) {
          _log(
            'Associated users load failed',
            data: {'error': error.toString(), 'page': page},
          );
          hasNext = false;
        },
      );
      if (!fetchedPage) {
        break;
      }
    }

    if (!ref.mounted) {
      return;
    }

    final currentPlatformUserId = _currentPlatformUserId.trim().toLowerCase();
    final filtered = collected
        .where((user) => user.id.trim().toLowerCase() != currentPlatformUserId)
        .toList(growable: false);
    state = state.copyWith(associatedUsers: filtered);
    _notifyShellContentChanged();
  }

  String get currentPlatformUserId => _currentPlatformUserId;

  HealthMessengerBootstrapConfig? get _bootstrapConfig =>
      ref.read(healthMessengerSessionProvider).bootstrapConfig;

  String get _currentPlatformUserId =>
      _bootstrapConfig?.externalUserId.trim() ?? '';

  AssociatedUser? _associatedUserForPlatformId(String platformId) {
    final normalized = platformId.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final user in state.associatedUsers) {
      if (user.id.trim().toLowerCase() == normalized) {
        return user;
      }
    }
    return null;
  }

  TenantUser? _tenantUserForPlatformId(String platformId) {
    final normalized = platformId.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final user in state.users) {
      final providerId = user.providerUserId?.trim().toLowerCase() ?? '';
      if (providerId.isNotEmpty && providerId == normalized) {
        return user;
      }
    }
    return null;
  }

  Future<void> selectConversation(
    String conversationId, {
    bool tryReconnect = true,
  }) async {
    conversationId = conversationId.trim();
    final chatSession = _session;
    if (chatSession == null) {
      return;
    }

    if (conversationId.isEmpty) {
      _cancelSlowConversationHint();
      _selectRequestId++;
      final previousConversationId = state.selectedConversationId;
      state = state.copyWith(
        clearSelectedConversationId: true,
        clearLoadingConversationId: true,
        slowConversationHintActive: false,
        clearComposerReplyDraft: true,
        clearComposerEditDraft: true,
      );
      if (previousConversationId != null &&
          !isDraftConversationId(previousConversationId)) {
        await _leaveConversationRoom(chatSession, previousConversationId);
      }
      return;
    }

    // Only repeated taps on the conversation already opening are dropped.
    // Bailing out for *any* in-flight open would make a stale load block every
    // later open, so the thread would sit on its loading placeholder forever.
    if ((state.loadingConversationId?.trim() ?? '') == conversationId) {
      return;
    }

    final requestId = ++_selectRequestId;

    // Revisiting a conversation renders its cached messages right away, so the
    // refetch below runs without a loading placeholder.
    final hasCachedMessages = state.messagesByConversation.containsKey(
      conversationId,
    );

    _cancelSlowConversationHint();
    state = state.copyWith(
      selectedConversationId: conversationId,
      loadingConversationId: hasCachedMessages ? null : conversationId,
      clearLoadingConversationId: hasCachedMessages,
      slowConversationHintActive: false,
      clearComposerReplyDraft: true,
      clearComposerEditDraft: true,
    );

    if (isDraftConversationId(conversationId)) {
      state = state.copyWith(clearLoadingConversationId: true);
      return;
    }

    if (!hasCachedMessages) {
      _scheduleSlowConversationHint(conversationId);
    }

    try {
      await _loadMessages(conversationId).timeout(_loadMessagesTimeout);
      if (!ref.mounted || requestId != _selectRequestId) {
        return;
      }

      var connected = state.isSocketConnected;
      if (!connected && tryReconnect) {
        connected = await ensureSocketConnected();
      }
      if (!connected || !ref.mounted || requestId != _selectRequestId) {
        return;
      }

      // Join only while the thread UI is visible. Joining from the list (or
      // before the mobile route opens) can make arrivals look read.
      if (chatSession.inbox.threadVisible) {
        await _joinConversationRoom(chatSession, conversationId);
      }
    } catch (error, stackTrace) {
      _log(
        'Select conversation failed',
        data: {
          'conversationId': conversationId,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      if (!hasCachedMessages) {
        _snack('Could not open conversation.');
      }
    } finally {
      _cancelSlowConversationHint();
      if (ref.mounted &&
          (state.loadingConversationId?.trim() ?? '') == conversationId) {
        state = state.copyWith(
          clearLoadingConversationId: true,
          slowConversationHintActive: false,
        );
      }
    }
  }

  /// Joins the realtime room without failing the open: messages already come
  /// from REST, so a socket problem must not surface as "could not open".
  Future<void> _joinConversationRoom(
    ChatSession chatSession,
    String conversationId,
  ) async {
    try {
      await chatSession
          .joinConversation(conversationId)
          .timeout(_socketRoomTimeout);
    } catch (error) {
      _log(
        'Join conversation room failed',
        data: {'conversationId': conversationId, 'error': error.toString()},
      );
    }
  }

  Future<void> _leaveConversationRoom(
    ChatSession chatSession,
    String conversationId,
  ) async {
    try {
      await chatSession
          .leaveConversation(conversationId)
          .timeout(_socketRoomTimeout);
    } catch (_) {}
  }

  Future<void> openDirectChat(MessengerUser user) async {
    final chatSession = _session;
    final currentUser = state.currentUser;
    final auth = _sessionAuth;
    final client = _client;
    if (chatSession == null ||
        currentUser == null ||
        auth == null ||
        client == null) {
      _snack('Chat is not ready yet.');
      throw StateError('Chat is not ready.');
    }

    state = state.copyWith(suggestedPeopleOpeningUserId: user.id.trim());
    try {
      final platformPeerId = user.id.trim();
      final peerTenantUser = _tenantUserForPlatformId(platformPeerId);
      final peerChatUserId = peerTenantUser?.id.trim() ?? '';

      if (peerChatUserId.isNotEmpty) {
        final existing = _findDirectConversation(
          currentUser.id,
          peerChatUserId,
        );
        if (existing != null) {
          await selectConversation(existing.id);
          return;
        }

        final resolved = await client.resolveDirectConversation(
          auth,
          currentUserId: currentUser.id,
          peerUserId: peerChatUserId,
          seedConversations: state.conversations,
        );
        await refreshAll();
        await selectConversation(resolved.conversation.id);
        return;
      }

      final peerAssociated = _associatedUserForPlatformId(platformPeerId);
      final bootstrapConfig = _bootstrapConfig;
      if (peerAssociated == null || bootstrapConfig == null) {
        _snack('Unknown person; refresh and try again.');
        throw StateError('Unknown person for direct chat.');
      }

      final created = await client.startConversation(
        auth,
        users: [
          AssociatedUserMessengerMapper.registrationBodyForSignedInUser(
            bootstrapConfig,
          ),
          AssociatedUserMessengerMapper.toRegistrationBody(
            peerAssociated,
            externalTenantId: bootstrapConfig.externalTenantId,
          ),
        ],
      );
      await refreshAll();
      await selectConversation(created.id);
    } catch (error, stackTrace) {
      _log(
        'openDirectChat failed',
        data: {'error': error.toString(), 'stackTrace': stackTrace.toString()},
      );
      _snack('Could not start conversation.');
      // Rethrow so the mobile shell does not push a stale thread route.
      rethrow;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(suggestedPeopleOpeningUserId: '');
      }
    }
  }

  Future<void> createGroupChatFromRequest(
    MessengerGroupCreateRequest request,
  ) async {
    final client = _client;
    final auth = _sessionAuth;
    final currentUser = state.currentUser;
    if (client == null || auth == null || currentUser == null) {
      _snack('Chat is not ready yet.');
      throw StateError('Chat is not ready.');
    }

    final groupName = request.groupName.trim();
    final uniqueUsers = <MessengerUser>[];
    final seenIds = <String>{};
    for (final user in request.selectedUsers) {
      final id = user.id.trim();
      if (id.isEmpty || !seenIds.add(id)) {
        continue;
      }
      uniqueUsers.add(user);
    }

    if (uniqueUsers.isEmpty) {
      _snack('Select at least one person to create a group.');
      throw StateError('At least one user is required.');
    }

    state = state.copyWith(isCreatingGroup: true);
    try {
      final bootstrapConfig = _bootstrapConfig;
      final chatParticipantIds = <String>[];
      var allResolvedToChatUsers = uniqueUsers.isNotEmpty;

      for (final user in uniqueUsers) {
        final tenantUser = _tenantUserForPlatformId(user.id.trim());
        if (tenantUser == null) {
          allResolvedToChatUsers = false;
          break;
        }
        chatParticipantIds.add(tenantUser.id.trim());
      }

      late final Conversation created;
      if (allResolvedToChatUsers) {
        created = await client.createConversation(
          auth,
          type: 'GROUP',
          title: request.startConversationGroupName(
            fallback: groupName.isEmpty ? 'Group' : groupName,
          ),
          creatorUserId: currentUser.id.trim(),
          participantIds: chatParticipantIds,
        );
      } else {
        if (bootstrapConfig == null) {
          _snack('Chat is not ready yet.');
          throw StateError('Chat bootstrap config is missing.');
        }

        final peerBodies = <ChatUserRegistrationBody>[];
        for (final user in uniqueUsers) {
          final associated = _associatedUserForPlatformId(user.id.trim());
          if (associated == null) {
            _snack('Unknown suggested person; refresh and try again.');
            throw StateError('Could not resolve group member ${user.id}.');
          }
          peerBodies.add(
            AssociatedUserMessengerMapper.toRegistrationBody(
              associated,
              externalTenantId: bootstrapConfig.externalTenantId,
            ),
          );
        }

        created = await client.startGroupConversation(
          auth,
          users: [
            AssociatedUserMessengerMapper.registrationBodyForSignedInUser(
              bootstrapConfig,
            ),
            ...peerBodies,
          ],
          groupName: groupName.isEmpty ? null : groupName,
        );
      }

      await refreshAll();
      await selectConversation(created.id);
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isCreatingGroup: false);
      }
    }
  }

  Future<bool> sendTextMessage(String text) async {
    final client = _client;
    var conversationId = state.selectedConversationId;
    final trimmed = text.trim();
    if (client == null || conversationId == null || trimmed.isEmpty) {
      return false;
    }

    final replyId = state.composerReplyDraft?.targetMessageId.trim() ?? '';
    final replyToMessageId = replyId.isEmpty ? null : replyId;

    state = state.copyWith(isSending: true);
    try {
      final connected = await ensureSocketConnected();
      if (!connected) {
        return false;
      }

      if (isDraftConversationId(conversationId)) {
        final realId = await _materializeDraftDirectConversation(
          conversationId,
        );
        if (realId == null || !ref.mounted) {
          return false;
        }
        conversationId = realId;
      }

      final created = await client.sendMessage(
        conversationId: conversationId,
        type: MessageType.text,
        content: trimmed,
        replyToMessageId: replyToMessageId,
      );
      _upsertMessage(conversationId, _normalizeOutgoingMessage(created));
      _session?.inbox.bumpConversation(conversationId);
      state = state.copyWith(clearComposerReplyDraft: true);
      return true;
    } catch (error, stackTrace) {
      _log(
        'Send message failed',
        data: {'error': error.toString(), 'stackTrace': stackTrace.toString()},
      );
      _snack('Could not send the message.');
      return false;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isSending: false);
      }
    }
  }

  Future<void> reactToMessage(String messageId, String reactionType) async {
    final client = _client;
    final conversationId = state.selectedConversationId;
    final currentUser = state.currentUser;
    if (client == null || conversationId == null || currentUser == null) {
      return;
    }

    state = state.copyWith(
      pendingReactionRequests: state.pendingReactionRequests + 1,
    );
    _applyReaction(
      conversationId,
      MessageReaction(
        id: 'pending-${currentUser.id}-$messageId',
        messageId: messageId,
        userId: currentUser.id,
        reactionType: reactionType,
        conversationId: conversationId,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    try {
      final reaction = await client.reactToMessage(
        conversationId: conversationId,
        messageId: messageId,
        reactionType: reactionType,
      );
      _applyReaction(conversationId, reaction);
    } catch (error) {
      _revertReaction(
        conversationId: conversationId,
        messageId: messageId,
        userId: currentUser.id,
      );
      _snack('Could not add the reaction.');
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          pendingReactionRequests: state.pendingReactionRequests - 1,
        );
      }
    }
  }

  Future<void> removeReactionFromMessage(
    String messageId,
    String reactionType,
  ) async {
    final client = _client;
    final conversationId = state.selectedConversationId;
    final currentUser = state.currentUser;
    if (client == null || conversationId == null || currentUser == null) {
      return;
    }

    final priorReaction = _reactionForUser(
      conversationId: conversationId,
      messageId: messageId,
      userId: currentUser.id,
    );

    state = state.copyWith(
      pendingReactionRequests: state.pendingReactionRequests + 1,
    );
    _applyReactionRemoval(
      conversationId,
      RemovedReactionEvent(
        messageId: messageId,
        conversationId: conversationId,
        userId: currentUser.id,
      ),
    );
    try {
      final removed = await client.removeReaction(
        conversationId: conversationId,
        messageId: messageId,
      );
      if (!removed && priorReaction != null) {
        _applyReaction(conversationId, priorReaction);
        _snack('No reaction was removed.');
      }
    } catch (error) {
      if (priorReaction != null) {
        _applyReaction(conversationId, priorReaction);
      }
      _snack('Could not remove the reaction.');
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          pendingReactionRequests: state.pendingReactionRequests - 1,
        );
      }
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final actions = _hostActions;
    final auth = _sessionAuth;
    final currentUser = state.currentUser;
    final conversationId = state.selectedConversationId;
    if (actions == null ||
        auth == null ||
        currentUser == null ||
        conversationId == null ||
        isDraftConversationId(conversationId)) {
      return;
    }

    final priorMessage = _messageById(conversationId, messageId);
    _applyDeletedMessage(
      DeletedMessageEvent(
        messageId: messageId,
        conversationId: conversationId,
        deletedAt: DateTime.now().toUtc(),
        userId: currentUser.id,
      ),
    );

    // Close the confirm dialog immediately; persist on the server in background.
    unawaited(
      _persistDeletedMessage(
        actions: actions,
        auth: auth,
        conversationId: conversationId,
        messageId: messageId,
        userId: currentUser.id,
        priorMessage: priorMessage,
      ),
    );
  }

  Future<void> _persistDeletedMessage({
    required MessengerHostActions actions,
    required ChatAuth auth,
    required String conversationId,
    required String messageId,
    required String userId,
    required ChatMessage? priorMessage,
  }) async {
    try {
      final result = await actions.deleteMessage(
        auth,
        conversationId: conversationId,
        messageId: messageId,
        userId: userId,
      );
      if (!ref.mounted) {
        return;
      }
      _applyDeletedMessage(
        DeletedMessageEvent(
          messageId: result.messageId,
          conversationId: result.conversationId,
          deletedAt: result.deletedAt ?? DateTime.now().toUtc(),
          userId: userId,
        ),
      );
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      if (priorMessage != null) {
        _upsertMessage(conversationId, priorMessage);
      }
      _snack('Could not delete the message.');
    }
  }

  Future<bool> editMessage(String messageId, String newText) async {
    final actions = _hostActions;
    final conversationId = state.selectedConversationId;
    final trimmed = newText.trim();
    if (actions == null ||
        conversationId == null ||
        isDraftConversationId(conversationId) ||
        trimmed.isEmpty) {
      return false;
    }

    final priorMessage = _messageById(conversationId, messageId);
    if (priorMessage != null) {
      _upsertMessage(
        conversationId,
        priorMessage.copyWith(
          content: trimmed,
          editedAt: DateTime.now().toUtc(),
        ),
      );
    }

    unawaited(
      _persistEditedMessage(
        actions: actions,
        conversationId: conversationId,
        messageId: messageId,
        content: trimmed,
        priorMessage: priorMessage,
      ),
    );
    return true;
  }

  Future<void> _persistEditedMessage({
    required MessengerHostActions actions,
    required String conversationId,
    required String messageId,
    required String content,
    required ChatMessage? priorMessage,
  }) async {
    try {
      final edited = await actions.editMessage(
        conversationId: conversationId,
        messageId: messageId,
        content: content,
      );
      if (!ref.mounted) {
        return;
      }
      _upsertMessage(conversationId, edited);
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      if (priorMessage != null) {
        _upsertMessage(conversationId, priorMessage);
      }
      _snack('Could not edit the message.');
    }
  }

  void beginComposerEdit(String messageId) {
    final trimmedId = messageId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    state = state.copyWith(
      composerEditDraft: MessengerComposerEditDraft(messageId: trimmedId),
      clearComposerReplyDraft: true,
    );
    _notifyShellContentChanged();
  }

  void clearComposerEdit() {
    state = state.copyWith(clearComposerEditDraft: true);
    _notifyShellContentChanged();
  }

  Future<bool> submitComposerEdit(String newText) async {
    final draft = state.composerEditDraft;
    if (draft == null) {
      return false;
    }
    final trimmed = newText.trim();
    if (trimmed.isEmpty) {
      _snack('Message cannot be empty.');
      return false;
    }
    final success = await editMessage(draft.messageId, trimmed);
    if (success && ref.mounted) {
      clearComposerEdit();
    }
    return success;
  }

  Future<void> deleteConversation(
    MessengerConversation conversationView,
  ) async {
    final actions = _hostActions;
    final auth = _sessionAuth;
    final currentUser = state.currentUser;
    final conversationId = conversationView.id.trim();
    if (actions == null ||
        auth == null ||
        currentUser == null ||
        conversationId.isEmpty ||
        isDraftConversationId(conversationId)) {
      _snack('Chat is not ready yet.');
      throw StateError('Chat is not ready.');
    }

    try {
      await actions.deleteConversation(
        auth,
        conversationId: conversationId,
        actorUserId: currentUser.id,
      );
      if (state.selectedConversationId == conversationId) {
        final nextMessages = Map<String, List<ChatMessage>>.from(
          state.messagesByConversation,
        )..remove(conversationId);
        state = state.copyWith(
          messagesByConversation: nextMessages,
          clearSelectedConversationId: true,
          clearComposerReplyDraft: true,
          clearComposerEditDraft: true,
        );
      }
      await refreshAll();
      _snack('Chat deleted.');
    } catch (error, stackTrace) {
      _log(
        'deleteConversation failed',
        data: {
          'conversationId': conversationId,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      _snack('Could not delete the chat.');
      rethrow;
    }
  }

  Future<List<ConversationParticipant>> listGroupMembers(
    String conversationId,
  ) async {
    final actions = _hostActions;
    final auth = _sessionAuth;
    final currentUser = state.currentUser;
    final id = conversationId.trim();
    if (actions == null ||
        auth == null ||
        currentUser == null ||
        id.isEmpty ||
        isDraftConversationId(id)) {
      throw StateError('Chat is not ready.');
    }

    try {
      return await actions.listGroupMembers(
        auth,
        conversationId: id,
        forUserId: currentUser.id,
      );
    } catch (error) {
      final local = conversationById(id);
      if (local != null) {
        return List<ConversationParticipant>.from(local.participants);
      }
      rethrow;
    }
  }

  Future<void> addGroupMembers(
    MessengerConversation conversationView,
    List<MessengerUser> users,
  ) async {
    final actions = _hostActions;
    final auth = _sessionAuth;
    final currentUser = state.currentUser;
    final conversationId = conversationView.id.trim();
    if (actions == null ||
        auth == null ||
        currentUser == null ||
        conversationId.isEmpty ||
        isDraftConversationId(conversationId)) {
      _snack('Chat is not ready yet.');
      throw StateError('Chat is not ready.');
    }

    final uniqueUsers = <MessengerUser>[];
    final seen = <String>{};
    for (final user in users) {
      final id = user.id.trim();
      if (id.isEmpty || !seen.add(id)) {
        continue;
      }
      if (isUserInGroup(conversationId, user)) {
        continue;
      }
      uniqueUsers.add(user);
    }
    if (uniqueUsers.isEmpty) {
      _snack('Select at least one person who is not already in the group.');
      return;
    }

    try {
      for (final user in uniqueUsers) {
        final chatUserId = await _resolveChatUserIdForMessengerUser(user);
        if (chatUserId == null || chatUserId.isEmpty) {
          throw StateError('Could not resolve participant ${user.id}.');
        }
        await actions.addGroupMember(
          auth,
          conversationId: conversationId,
          userId: chatUserId,
          actorUserId: currentUser.id,
        );
      }
      await refreshAll();
      _snack(
        uniqueUsers.length == 1
            ? '1 person added.'
            : '${uniqueUsers.length} people added.',
      );
    } catch (error, stackTrace) {
      _log(
        'addGroupMembers failed',
        data: {
          'conversationId': conversationId,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      _snack('Could not add people to the group.');
      rethrow;
    }
  }

  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  }) async {
    final actions = _hostActions;
    final auth = _sessionAuth;
    final currentUser = state.currentUser;
    final id = conversationId.trim();
    final memberId = userId.trim();
    if (actions == null ||
        auth == null ||
        currentUser == null ||
        id.isEmpty ||
        memberId.isEmpty ||
        isDraftConversationId(id)) {
      _snack('Chat is not ready yet.');
      throw StateError('Chat is not ready.');
    }

    try {
      await actions.removeGroupMember(
        auth,
        conversationId: id,
        userId: memberId,
        actorUserId: currentUser.id,
      );
      await refreshAll();
      _snack('Member removed.');
    } catch (error, stackTrace) {
      _log(
        'removeGroupMember failed',
        data: {
          'conversationId': id,
          'userId': memberId,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      _snack('Could not remove the member.');
      rethrow;
    }
  }

  Future<void> renameGroupConversation(
    MessengerConversation conversationView,
    String title,
  ) async {
    final client = _client;
    final auth = _sessionAuth;
    final currentUser = state.currentUser;
    final conversationId = conversationView.id.trim();
    final trimmed = title.trim();
    if (client == null ||
        auth == null ||
        currentUser == null ||
        conversationId.isEmpty ||
        trimmed.isEmpty ||
        isDraftConversationId(conversationId)) {
      _snack('Chat is not ready yet.');
      throw StateError('Chat is not ready.');
    }

    try {
      await client.updateConversation(
        auth,
        conversationId: conversationId,
        title: trimmed,
        actorUserId: currentUser.id,
      );
      await refreshAll();
      _snack('Group updated.');
    } catch (error, stackTrace) {
      _log(
        'renameGroupConversation failed',
        data: {
          'conversationId': conversationId,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      _snack('Could not update the group.');
      rethrow;
    }
  }

  Conversation? conversationById(String conversationId) {
    final id = conversationId.trim();
    if (id.isEmpty) {
      return null;
    }
    for (final conversation in state.conversations) {
      if (conversation.id == id) {
        return conversation;
      }
    }
    return null;
  }

  bool isUserInGroup(String conversationId, MessengerUser user) {
    final conversation = conversationById(conversationId);
    if (conversation == null) {
      return false;
    }
    final platformId = user.id.trim().toLowerCase();
    if (platformId.isEmpty) {
      return false;
    }
    final resolvedChatId =
        _tenantUserForPlatformId(user.id)?.id.trim().toLowerCase() ?? '';
    for (final participant in conversation.participants) {
      final participantChatId = participant.user.id.trim().toLowerCase();
      final participantUserId = participant.userId.trim().toLowerCase();
      if (participantChatId == platformId || participantUserId == platformId) {
        return true;
      }
      if (resolvedChatId.isNotEmpty &&
          (participantChatId == resolvedChatId ||
              participantUserId == resolvedChatId)) {
        return true;
      }
    }
    return false;
  }

  Future<String?> _resolveChatUserIdForMessengerUser(MessengerUser user) async {
    final platformId = user.id.trim();
    if (platformId.isEmpty) {
      return null;
    }

    final existing = _tenantUserForPlatformId(platformId);
    final existingId = existing?.id.trim() ?? '';
    if (existingId.isNotEmpty) {
      return existingId;
    }

    for (final tenantUser in state.users) {
      if (tenantUser.id.trim() == platformId) {
        return platformId;
      }
    }

    final associated = _associatedUserForPlatformId(platformId);
    final bootstrapConfig = _bootstrapConfig;
    final auth = _sessionAuth;
    final client = _client;
    if (associated == null ||
        bootstrapConfig == null ||
        auth == null ||
        client == null) {
      return null;
    }

    final registration = AssociatedUserMessengerMapper.toRegistrationBody(
      associated,
      externalTenantId: bootstrapConfig.externalTenantId,
    );
    final tenantUser = await client.registerOrGetUser(
      auth,
      externalTenantId: registration.externalTenantId,
      externalUserId: registration.externalUserId,
      externalUserRole: registration.externalUserRole,
      email: registration.email,
      name: registration.name,
      profile: registration.profile,
    );
    final resolved = tenantUser.id.trim();
    return resolved.isEmpty ? null : resolved;
  }

  /// Joins the selected conversation socket room.
  ///
  /// Call when the thread UI is opening (or already visible). Do not call from
  /// list-only selection — joining in the background can mark messages read.
  Future<void> joinSelectedConversationRoom() async {
    final chatSession = _session;
    final conversationId = state.selectedConversationId?.trim() ?? '';
    if (chatSession == null ||
        conversationId.isEmpty ||
        isDraftConversationId(conversationId)) {
      return;
    }
    await _joinConversationRoom(chatSession, conversationId);
  }

  Future<void> markSeen(String messageId) async {
    final client = _client;
    final auth = _sessionAuth;
    final conversationId = state.selectedConversationId;
    final inbox = _session?.inbox;
    if (client == null ||
        auth == null ||
        conversationId == null ||
        isDraftConversationId(conversationId) ||
        inbox == null ||
        !inbox.threadVisible) {
      return;
    }

    try {
      await client.markAsReadRest(
        auth,
        conversationId: conversationId,
        messageId: messageId,
      );
    } catch (_) {
      if (state.isSocketConnected) {
        try {
          await client.markAsRead(
            conversationId: conversationId,
            messageId: messageId,
          );
        } catch (_) {}
      }
    }
  }

  Future<void> onTypingStart(String conversationId) async {
    if (isDraftConversationId(conversationId) ||
        !state.isSocketConnected ||
        _client == null) {
      return;
    }
    try {
      await _client!.startTyping(conversationId);
    } catch (_) {}
  }

  Future<void> onTypingStop(String conversationId) async {
    if (isDraftConversationId(conversationId) ||
        !state.isSocketConnected ||
        _client == null) {
      return;
    }
    try {
      await _client!.stopTyping(conversationId);
    } catch (_) {}
  }

  void updateComposerReplyDraft(MessengerComposerReplyDraft? draft) {
    state = state.copyWith(
      composerReplyDraft: draft,
      clearComposerReplyDraft: draft == null,
    );
    _notifyShellContentChanged();
  }

  void setMediaUploading(bool value) {
    state = state.copyWith(isMediaUploading: value);
  }

  void upsertMediaMessage(String conversationId, ChatMessage message) {
    _upsertMessage(conversationId, _normalizeOutgoingMessage(message));
    _session?.inbox.bumpConversation(conversationId);
  }

  bool canDeleteMessage(MessengerChatMessage message) {
    return _mappers.isMessageFromCurrentUser(senderId: message.senderId) &&
        !message.isDeleted;
  }

  bool canEditMessengerMessage(MessengerChatMessage message) {
    return _mappers.isMessageFromCurrentUser(senderId: message.senderId) &&
        !message.isDeleted &&
        message.type == MessengerMessageType.text;
  }

  List<MessengerConversation> messengerConversationsFor({
    required Map<String, int> unreadMap,
    required ConversationOrderSnapshot orderSnapshot,
  }) {
    return state.conversations
        .asMap()
        .entries
        .map(
          (entry) => _mappers.mapConversation(
            conversation: entry.value,
            unreadMap: unreadMap,
            orderSnapshot: orderSnapshot,
            localMessages:
                state.messagesByConversation[entry.value.id] ?? const [],
            fallbackApiRank: entry.key,
          ),
        )
        .toList(growable: false);
  }

  List<MessengerUser> get uiUsers {
    return state.associatedUsers
        .map(_mapAssociatedUserToMessengerUser)
        .toList(growable: false);
  }

  MessengerUser _mapAssociatedUserToMessengerUser(AssociatedUser associated) {
    final base = AssociatedUserMessengerMapper.toMessengerUser(associated);
    final tenant = _tenantUserForPlatformId(associated.id);
    final chatUserId = tenant?.id.trim() ?? '';
    final isOnline = chatUserId.isNotEmpty
        ? (_remotePresenceByUserId[chatUserId] ?? tenant?.isOnline ?? false)
        : base.isOnline;
    return MessengerUser(
      id: base.id,
      externalUserId: chatUserId.isEmpty ? null : chatUserId,
      username: base.username,
      roleLabel: base.roleLabel,
      email: base.email,
      isOnline: isOnline,
      avatarUrl: base.avatarUrl,
    );
  }

  /// Resolves a platform user id (associated-user id) to a [MessengerUser]
  /// for programmatic opens such as care-team deep links.
  MessengerUser messengerUserForPlatformId(String platformId) {
    final trimmed = platformId.trim();
    if (trimmed.isEmpty) {
      return const MessengerUser(id: '', username: 'Contact');
    }

    final associated = _associatedUserForPlatformId(trimmed);
    if (associated != null) {
      final mapped = AssociatedUserMessengerMapper.toMessengerUser(associated);
      final tenant = _tenantUserForPlatformId(trimmed);
      final chatUserId = tenant?.id.trim() ?? '';
      final isOnline = chatUserId.isNotEmpty
          ? (_remotePresenceByUserId[chatUserId] ?? tenant?.isOnline ?? false)
          : mapped.isOnline;
      if (isOnline == mapped.isOnline) {
        return mapped;
      }
      return MessengerUser(
        id: mapped.id,
        username: mapped.username,
        roleLabel: mapped.roleLabel,
        email: mapped.email,
        isOnline: isOnline,
        avatarUrl: mapped.avatarUrl,
      );
    }

    for (final user in uiUsers) {
      if (user.id.trim() == trimmed) {
        return user;
      }
    }

    final tenant = _tenantUserForPlatformId(trimmed);
    if (tenant != null) {
      return _mappers.mapTenantUser(tenant);
    }

    return MessengerUser(id: trimmed, username: 'Contact');
  }

  List<MessengerChatMessage> get activeMessages {
    final conversationId = state.selectedConversationId;
    if (conversationId == null || isDraftConversationId(conversationId)) {
      return const [];
    }
    final source = state.messagesByConversation[conversationId] ?? const [];
    return source.map(_mappers.mapMessage).toList(growable: false);
  }

  List<MessengerTypingUser> get remoteTypingUsers {
    final conversationId = state.selectedConversationId;
    if (conversationId == null) {
      return const [];
    }
    final ids = state.typingUserIdsByConversation[conversationId];
    if (ids == null || ids.isEmpty) {
      return const [];
    }
    final selfId = state.currentUser?.id ?? '';
    return ids
        .where((id) => id.isNotEmpty && id != selfId)
        .map(
          (id) =>
              MessengerTypingUser(userId: id, displayLabel: _nameForUser(id)),
        )
        .toList(growable: false);
  }

  Future<bool> ensureSocketConnected() async {
    final sessionNotifier = ref.read(healthMessengerSessionProvider.notifier);
    var sessionState = ref.read(healthMessengerSessionProvider);
    if (sessionState.session == null) {
      await sessionNotifier.recoverConnection(force: true);
      if (!ref.mounted) {
        return false;
      }
      sessionState = ref.read(healthMessengerSessionProvider);
      if (sessionState.session == null) {
        return false;
      }
    }

    if (sessionState.session!.isSocketConnected) {
      if (ref.mounted && !state.isSocketConnected) {
        state = state.copyWith(isSocketConnected: true);
      }
      return true;
    }

    final connectionState = sessionState.connectionState;
    final inProgress = HealthMessengerConnectionRecovery.isSocketInProgress(
      connectionState,
    );
    if (!inProgress) {
      await sessionNotifier.recoverConnection(force: true);
      if (!ref.mounted) {
        return false;
      }
    }

    final connected = await sessionNotifier.waitUntilSocketConnected();
    if (ref.mounted) {
      state = state.copyWith(isSocketConnected: connected);
    }
    return connected;
  }

  Future<void> logoutAndClear() async {
    state = state.copyWith(isLoggingOut: true);
    try {
      await detachFromSession();
      await ref.read(healthMessengerSessionProvider.notifier).stopSession();
      if (ref.mounted) {
        state = const HealthMessengerChatState();
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoggingOut: false);
      }
    }
  }

  Future<void> onMobileThreadClosed(String conversationId) async {
    final id = conversationId.trim();
    if (id.isEmpty || isDraftConversationId(id)) {
      return;
    }

    // Deselect before awaiting the socket leave. Awaiting first lets the user
    // reopen the thread in between, and this close would then wipe that fresh
    // selection — leaving the thread with no messages and no load in flight.
    if ((state.selectedConversationId?.trim() ?? '') == id) {
      _cancelSlowConversationHint();
      _selectRequestId++;
      state = state.copyWith(
        clearSelectedConversationId: true,
        clearLoadingConversationId: true,
        slowConversationHintActive: false,
        clearComposerReplyDraft: true,
        clearComposerEditDraft: true,
      );
    }

    final chatSession = _session;
    if (chatSession == null) {
      return;
    }
    await _leaveConversationRoom(chatSession, id);

    // A reopen that landed during the leave round-trip lost its room; rejoin.
    if (ref.mounted && (state.selectedConversationId?.trim() ?? '') == id) {
      await _joinConversationRoom(chatSession, id);
    }
  }

  Future<String?> prepareOutgoingConversation(String conversationId) async {
    if (!isDraftConversationId(conversationId)) {
      return conversationId;
    }
    return _materializeDraftDirectConversation(conversationId);
  }

  bool isDraftConversationId(String? id) {
    final trimmed = id?.trim() ?? '';
    return trimmed.startsWith(_draftDirectPrefix);
  }

  Future<void> _loadMessages(
    String conversationId, {
    bool scrollToEnd = true,
  }) async {
    conversationId = conversationId.trim();
    if (conversationId.isEmpty || isDraftConversationId(conversationId)) {
      return;
    }

    final client = _client;
    final auth = _sessionAuth;
    if (client == null || auth == null) {
      return;
    }

    final page = await client.getMessages(auth, conversationId);
    final items = [...page.items]
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    if (!ref.mounted) {
      return;
    }

    final next = Map<String, List<ChatMessage>>.from(
      state.messagesByConversation,
    );
    next[conversationId] = items;
    state = state.copyWith(messagesByConversation: next);
    if (scrollToEnd) {
      onRequestScrollToBottom?.call();
    }
  }

  Conversation? _findDirectConversation(String currentUserId, String peerId) {
    for (final conversation in state.conversations) {
      if (conversation.type.toUpperCase() != 'DIRECT') {
        continue;
      }
      final participantIds = conversation.participants
          .map((participant) => participant.user.id)
          .toSet();
      if (participantIds.contains(currentUserId) &&
          participantIds.contains(peerId)) {
        return conversation;
      }
    }
    return null;
  }

  Future<String?> _materializeDraftDirectConversation(String draftId) async {
    final client = _client;
    final auth = _sessionAuth;
    final currentUser = state.currentUser;
    if (client == null || auth == null || currentUser == null) {
      return null;
    }

    final peerId = draftId.substring(_draftDirectPrefix.length).trim();
    if (peerId.isEmpty) {
      return null;
    }

    final resolved = await client.resolveDirectConversation(
      auth,
      currentUserId: currentUser.id,
      peerUserId: peerId,
      seedConversations: state.conversations,
    );
    final realId = resolved.conversation.id;
    await refreshAll();
    if (ref.mounted) {
      state = state.copyWith(selectedConversationId: realId);
    }
    return realId;
  }

  void _listenToSocketEvents(ChatClient client) {
    _socketSubscription?.cancel();
    _socketSubscription = client.events.listen(_handleSocketEvent);
  }

  void _handleSocketEvent(ChatSocketEvent event) {
    if (!ref.mounted) {
      return;
    }

    switch (event.type) {
      case ChatSocketEventType.connected:
        state = state.copyWith(isSocketConnected: true);
        unawaited(joinSelectedConversationRoom());
      case ChatSocketEventType.disconnected:
        state = state.copyWith(isSocketConnected: false);
      case ChatSocketEventType.error:
        state = state.copyWith(isSocketConnected: false);
      case ChatSocketEventType.messageReceived:
        final message = event.message;
        if (message != null) {
          _clearTypingForUser(message.conversationId, message.senderId);
          _upsertMessage(message.conversationId, message);
        }
      case ChatSocketEventType.messageReacted:
        final reaction = event.reaction;
        if (reaction?.conversationId != null) {
          _applyReaction(reaction!.conversationId!, reaction);
        }
      case ChatSocketEventType.reactionRemoved:
        final removedReaction = event.removedReaction;
        if (removedReaction != null) {
          _applyReactionRemoval(
            removedReaction.conversationId,
            removedReaction,
          );
        }
      case ChatSocketEventType.messageDeleted:
        final deletedMessage = event.deletedMessage;
        if (deletedMessage != null) {
          _applyDeletedMessage(deletedMessage);
        }
      case ChatSocketEventType.messageEdited:
        final editedMessage = event.editedMessage;
        if (editedMessage != null) {
          _upsertMessage(editedMessage.conversationId, editedMessage.message);
        }
      case ChatSocketEventType.conversationCreated:
        final createdConversation = event.conversationCreated;
        if (createdConversation != null) {
          final next = [...state.conversations];
          final index = next.indexWhere(
            (item) => item.id == createdConversation.conversation.id,
          );
          if (index == -1) {
            next.insert(0, createdConversation.conversation);
          } else {
            next[index] = createdConversation.conversation;
          }
          state = state.copyWith(conversations: next);
          _session?.inbox.seedFromConversations(next);
        }
      case ChatSocketEventType.conversationMessage:
        final conversationMessage = event.conversationMessage;
        if (conversationMessage != null) {
          _clearTypingForUser(
            conversationMessage.conversationId,
            conversationMessage.message.senderId,
          );
          _upsertMessage(
            conversationMessage.conversationId,
            conversationMessage.message,
          );
        }
      case ChatSocketEventType.userTyping:
        final typing = event.typing;
        if (typing != null &&
            typing.userId.isNotEmpty &&
            typing.conversationId.isNotEmpty) {
          final selfId = state.currentUser?.id ?? '';
          if (selfId.isEmpty || typing.userId != selfId) {
            final nextTyping = Map<String, Set<String>>.from(
              state.typingUserIdsByConversation,
            );
            nextTyping
                .putIfAbsent(typing.conversationId, () => <String>{})
                .add(typing.userId);
            state = state.copyWith(typingUserIdsByConversation: nextTyping);
            _scheduleTypingExpiry(typing.conversationId, typing.userId);
            _notifyShellContentChanged();
          }
        }
      case ChatSocketEventType.userStoppedTyping:
        final typing = event.typing;
        if (typing != null &&
            typing.userId.isNotEmpty &&
            typing.conversationId.isNotEmpty) {
          _cancelTypingExpiry(typing.conversationId, typing.userId);
          final nextTyping = Map<String, Set<String>>.from(
            state.typingUserIdsByConversation,
          );
          nextTyping[typing.conversationId]?.remove(typing.userId);
          state = state.copyWith(typingUserIdsByConversation: nextTyping);
          _notifyShellContentChanged();
        }
      case ChatSocketEventType.messageDelivered:
        final delivered = event.delivered;
        if (delivered != null) {
          _handleDeliveredReceipt(delivered);
        }
      case ChatSocketEventType.messageRead:
        final receipt = event.receipt;
        if (receipt != null) {
          _handleReadReceipt(receipt);
        }
      case ChatSocketEventType.unreadCountUpdated:
      case ChatSocketEventType.userBadgeUpdated:
      case ChatSocketEventType.userOnline:
      case ChatSocketEventType.userOffline:
        break;
    }
  }

  void _onMessengerPushEvent(MessengerPushEvent event) {
    final conversationId = event.conversationId?.trim();
    if (conversationId == null || conversationId.isEmpty) {
      return;
    }
    unawaited(refreshAll());
  }

  void _upsertMessage(String conversationId, ChatMessage message) {
    if (message.id.trim().isEmpty || conversationId.trim().isEmpty) {
      return;
    }
    final existing = state.messagesByConversation[conversationId] ?? const [];
    final next = List<ChatMessage>.from(existing);
    final index = next.indexWhere((item) => item.id == message.id);
    late final ChatMessage upserted;
    if (index == -1) {
      upserted = _normalizeMessageIdentity(message);
      next.add(upserted);
    } else {
      final prior = next[index];
      final merged = mergeMessageDeliveryReadSnapshot(
        prior,
        _coalesceDeletedMessageOnUpsert(prior, message),
      );
      upserted = _preserveMessageIdentity(prior, merged);
      next[index] = upserted;
    }
    next.sort((left, right) => left.createdAt.compareTo(right.createdAt));

    final nextMessages = Map<String, List<ChatMessage>>.from(
      state.messagesByConversation,
    );
    nextMessages[conversationId] = next;
    state = state.copyWith(messagesByConversation: nextMessages);
    _notifyShellContentChanged();
    _flushPendingReceiptsForMessage(
      conversationId: conversationId,
      messageId: upserted.id,
    );
  }

  /// Ensures own messages keep a stable sender id and at least SENT status.
  ChatMessage _normalizeOutgoingMessage(ChatMessage message) {
    final selfId = state.currentUser?.id.trim() ?? '';
    final resolvedSenderId = _resolveStoredMessageSenderId(message);
    final senderId = resolvedSenderId.isNotEmpty ? resolvedSenderId : selfId;
    final status = message.deliveryStatus?.trim();
    final deliveryStatus = (status == null || status.isEmpty) ? 'SENT' : status;
    if (senderId == message.senderId &&
        deliveryStatus == message.deliveryStatus) {
      return message;
    }
    return _cloneMessage(
      message,
      senderId: senderId.isEmpty ? message.senderId : senderId,
      deliveryStatus: deliveryStatus,
    );
  }

  ChatMessage _normalizeMessageIdentity(ChatMessage message) {
    final senderId = _resolveStoredMessageSenderId(message);
    if (senderId.isEmpty || senderId == message.senderId) {
      return message;
    }
    return _cloneMessage(message, senderId: senderId);
  }

  String _resolveStoredMessageSenderId(ChatMessage message) {
    final direct = message.senderId.trim();
    if (direct.isNotEmpty) {
      return _mappers.resolveChatUserId(direct);
    }
    final fromSender = message.sender?.id.trim() ?? '';
    if (fromSender.isNotEmpty) {
      return _mappers.resolveChatUserId(fromSender);
    }
    return '';
  }

  MessageReaction _normalizeReaction(MessageReaction reaction) {
    final userId = _mappers.resolveReactionUserId(reaction);
    final reactionType = _mappers.normalizeReactionType(reaction.reactionType);
    if (userId == reaction.userId.trim() &&
        reactionType == reaction.reactionType.trim()) {
      return reaction;
    }
    return MessageReaction(
      id: reaction.id,
      messageId: reaction.messageId,
      userId: userId.isEmpty ? reaction.userId : userId,
      reactionType: reactionType,
      conversationId: reaction.conversationId,
      createdAt: reaction.createdAt,
      user: reaction.user,
    );
  }

  bool _reactionBelongsToUser(MessageReaction reaction, String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return false;
    }
    return _mappers.resolveReactionUserId(reaction) == normalizedUserId;
  }

  /// Sparse socket echoes must not wipe sender id or regress deliveryStatus.
  ChatMessage _preserveMessageIdentity(ChatMessage prior, ChatMessage merged) {
    final senderId = merged.senderId.trim().isNotEmpty
        ? merged.senderId.trim()
        : (merged.sender?.id.trim().isNotEmpty == true
              ? merged.sender!.id.trim()
              : prior.senderId);
    final deliveryStatus = _preferDeliveryStatus(
      prior.deliveryStatus,
      merged.deliveryStatus,
    );
    if (senderId == merged.senderId &&
        deliveryStatus == merged.deliveryStatus) {
      return merged;
    }
    return _cloneMessage(
      merged,
      senderId: senderId,
      deliveryStatus: deliveryStatus,
    );
  }

  String? _preferDeliveryStatus(String? existing, String? incoming) {
    int rank(String? raw) {
      switch (raw?.trim().toUpperCase()) {
        case 'SEEN':
        case 'READ':
        case 'VIEWED':
        case 'R':
          return 3;
        case 'DELIVERED':
        case 'D':
          return 2;
        case 'SENT':
        case 'S':
        case 'SENDING':
          return 1;
        default:
          return 0;
      }
    }

    return rank(existing) >= rank(incoming) ? existing : incoming;
  }

  ChatMessage _cloneMessage(
    ChatMessage source, {
    String? senderId,
    String? deliveryStatus,
  }) {
    return ChatMessage(
      id: source.id,
      conversationId: source.conversationId,
      tenantId: source.tenantId,
      senderId: senderId ?? source.senderId,
      type: source.type,
      content: source.content,
      attachments: source.attachments,
      replyToMessageId: source.replyToMessageId,
      replyTo: source.replyTo,
      translatedMessage: source.translatedMessage,
      transcribedMessage: source.transcribedMessage,
      editedAt: source.editedAt,
      deletedAt: source.deletedAt,
      createdAt: source.createdAt,
      reactions: source.reactions,
      deliveredReceipts: source.deliveredReceipts,
      readReceipts: source.readReceipts,
      sender: source.sender,
      deliveryStatus: deliveryStatus ?? source.deliveryStatus,
      deliveredToCount: source.deliveredToCount,
      readByCount: source.readByCount,
    );
  }

  ChatMessage _coalesceDeletedMessageOnUpsert(
    ChatMessage existing,
    ChatMessage incoming,
  ) {
    if (!existing.isDeleted || incoming.isDeleted) {
      return incoming;
    }
    final inferredDeleted = incoming.content.trim() == '[deleted]';
    if (inferredDeleted) {
      return incoming.copyWith(
        deletedAt: existing.deletedAt,
        content: '[deleted]',
      );
    }
    return incoming.copyWith(
      deletedAt: existing.deletedAt,
      content: '[deleted]',
    );
  }

  void _handleDeliveredReceipt(DeliveredReceipt receipt) {
    final conversationId = _resolveReceiptConversationId(
      explicitConversationId: receipt.conversationId,
      messageId: receipt.messageId,
    );
    if (conversationId == null) {
      _bufferDeliveredReceipt(receipt);
      return;
    }
    final applied = _applyDeliveredReceipt(conversationId, receipt);
    if (!applied) {
      _bufferDeliveredReceipt(receipt);
    }
  }

  void _handleReadReceipt(ReadReceipt receipt) {
    final conversationId = _resolveReceiptConversationId(
      explicitConversationId: receipt.conversationId,
      messageId: receipt.messageId,
    );
    if (conversationId == null) {
      _bufferReadReceipt(receipt);
      return;
    }
    final applied = _applyReadReceipt(conversationId, receipt);
    if (!applied) {
      _bufferReadReceipt(receipt);
    }
  }

  String? _resolveReceiptConversationId({
    required String? explicitConversationId,
    required String messageId,
  }) {
    final explicit = explicitConversationId?.trim() ?? '';
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final mid = messageId.trim();
    if (mid.isEmpty) {
      return null;
    }
    for (final entry in state.messagesByConversation.entries) {
      if (entry.value.any((message) => message.id == mid)) {
        return entry.key;
      }
    }
    final selected = state.selectedConversationId?.trim() ?? '';
    return selected.isEmpty ? null : selected;
  }

  void _bufferDeliveredReceipt(DeliveredReceipt receipt) {
    final messageId = receipt.messageId.trim();
    if (messageId.isEmpty) {
      return;
    }
    final bucket = _pendingDeliveredByMessageId.putIfAbsent(
      messageId,
      () => <DeliveredReceipt>[],
    );
    bucket.removeWhere((item) => item.userId == receipt.userId);
    bucket.add(receipt);
  }

  void _bufferReadReceipt(ReadReceipt receipt) {
    final messageId = receipt.messageId.trim();
    if (messageId.isEmpty) {
      return;
    }
    final bucket = _pendingReadByMessageId.putIfAbsent(
      messageId,
      () => <ReadReceipt>[],
    );
    bucket.removeWhere((item) => item.userId == receipt.userId);
    bucket.add(receipt);
  }

  void _flushPendingReceiptsForMessage({
    required String conversationId,
    required String messageId,
  }) {
    final mid = messageId.trim();
    if (mid.isEmpty) {
      return;
    }
    final delivered = _pendingDeliveredByMessageId.remove(mid);
    if (delivered != null) {
      for (final receipt in delivered) {
        _applyDeliveredReceipt(conversationId, receipt);
      }
    }
    final read = _pendingReadByMessageId.remove(mid);
    if (read != null) {
      for (final receipt in read) {
        _applyReadReceipt(conversationId, receipt);
      }
    }
  }

  void _applyReaction(String conversationId, MessageReaction reaction) {
    final normalizedId = conversationId.trim();
    if (normalizedId.isEmpty) {
      return;
    }
    final normalizedReaction = _normalizeReaction(reaction);

    Map<String, List<ChatMessage>>? updatedMessages;
    final messages = state.messagesByConversation[normalizedId];
    if (messages != null) {
      final index = messages.indexWhere(
        (item) => item.id == normalizedReaction.messageId,
      );
      if (index != -1) {
        final target = messages[index];
        final nextReactions = List<MessageReaction>.from(target.reactions)
          ..removeWhere(
            (item) => _reactionBelongsToUser(item, normalizedReaction.userId),
          )
          ..add(normalizedReaction);
        final nextMessages = List<ChatMessage>.from(messages);
        nextMessages[index] = target.copyWith(reactions: nextReactions);
        updatedMessages = Map<String, List<ChatMessage>>.from(
          state.messagesByConversation,
        );
        updatedMessages[normalizedId] = nextMessages;
      }
    }

    final nextConversations = state.conversations
        .map(
          (conversation) => _mergeConversationWithReaction(
            conversation,
            conversationId: normalizedId,
            reaction: normalizedReaction,
          ),
        )
        .toList(growable: false);

    state = state.copyWith(
      messagesByConversation: updatedMessages ?? state.messagesByConversation,
      conversations: nextConversations,
    );

    _session?.inbox.bumpConversation(
      normalizedId,
      at: normalizedReaction.createdAt ?? DateTime.now().toUtc(),
    );
    _notifyShellContentChanged();
  }

  Conversation _mergeConversationWithReaction(
    Conversation conversation, {
    required String conversationId,
    required MessageReaction reaction,
  }) {
    if (conversation.id != conversationId) {
      return conversation;
    }
    final candidate = _latestReactionFromMessageReaction(reaction);
    final previous = conversation.latestReaction;
    if (previous != null && candidate.createdAt.isBefore(previous.createdAt)) {
      return conversation;
    }
    final nextUpdatedAt = candidate.createdAt.isAfter(conversation.updatedAt)
        ? candidate.createdAt
        : conversation.updatedAt;
    return Conversation(
      id: conversation.id,
      tenantId: conversation.tenantId,
      type: conversation.type,
      title: conversation.title,
      createdBy: conversation.createdBy,
      createdAt: conversation.createdAt,
      updatedAt: nextUpdatedAt,
      participants: conversation.participants,
      unreadCount: conversation.unreadCount,
      latestMessage: conversation.latestMessage,
      latestMessageId: conversation.latestMessageId,
      latestReaction: candidate,
      messageState: conversation.messageState,
      messageStatusByUserId: conversation.messageStatusByUserId,
    );
  }

  LatestReaction _latestReactionFromMessageReaction(MessageReaction reaction) {
    final normalized = _normalizeReaction(reaction);
    return LatestReaction(
      id: normalized.id,
      messageId: normalized.messageId,
      chatUserId: _mappers.resolveReactionUserId(normalized),
      reactionType: _mappers.normalizeReactionType(normalized.reactionType),
      userName: _reactionUserName(normalized),
      createdAt: normalized.createdAt ?? DateTime.now().toUtc(),
    );
  }

  String _reactionUserName(MessageReaction reaction) {
    final fromPayload = reaction.user?.name?.trim() ?? '';
    if (fromPayload.isNotEmpty) {
      return fromPayload;
    }
    return _nameForUser(reaction.userId);
  }

  void _revertReaction({
    required String conversationId,
    required String messageId,
    required String userId,
  }) {
    _applyReactionRemoval(
      conversationId,
      RemovedReactionEvent(
        messageId: messageId,
        conversationId: conversationId,
        userId: userId,
      ),
    );
  }

  MessageReaction? _reactionForUser({
    required String conversationId,
    required String messageId,
    required String userId,
  }) {
    final messages = state.messagesByConversation[conversationId];
    if (messages == null) {
      return null;
    }
    final index = messages.indexWhere((item) => item.id == messageId);
    if (index == -1) {
      return null;
    }
    for (final reaction in messages[index].reactions) {
      if (_reactionBelongsToUser(reaction, userId)) {
        return reaction;
      }
    }
    return null;
  }

  ChatMessage? _messageById(String conversationId, String messageId) {
    final messages = state.messagesByConversation[conversationId];
    if (messages == null) {
      return null;
    }
    for (final message in messages) {
      if (message.id == messageId) {
        return message;
      }
    }
    return null;
  }

  bool _applyDeliveredReceipt(String conversationId, DeliveredReceipt receipt) {
    final messages = state.messagesByConversation[conversationId];
    if (messages == null) {
      return false;
    }
    final index = messages.indexWhere((item) => item.id == receipt.messageId);
    if (index == -1) {
      return false;
    }
    final updatedMessage = _preserveMessageIdentity(
      messages[index],
      _cloneMessage(
        applyDeliveredReceiptToMessage(messages[index], receipt),
        deliveryStatus: 'DELIVERED',
      ),
    );
    final nextMessages = List<ChatMessage>.from(messages);
    nextMessages[index] = updatedMessage;
    final updated = Map<String, List<ChatMessage>>.from(
      state.messagesByConversation,
    );
    updated[conversationId] = nextMessages;
    state = state.copyWith(messagesByConversation: updated);
    _notifyShellContentChanged();
    return true;
  }

  bool _applyReadReceipt(String conversationId, ReadReceipt receipt) {
    final messages = state.messagesByConversation[conversationId];
    if (messages == null) {
      return false;
    }
    final index = messages.indexWhere((item) => item.id == receipt.messageId);
    if (index == -1) {
      return false;
    }
    final updatedMessage = _preserveMessageIdentity(
      messages[index],
      _cloneMessage(
        applyReadReceiptToMessage(messages[index], receipt),
        deliveryStatus: 'SEEN',
      ),
    );
    final nextMessages = List<ChatMessage>.from(messages);
    nextMessages[index] = updatedMessage;
    final updated = Map<String, List<ChatMessage>>.from(
      state.messagesByConversation,
    );
    updated[conversationId] = nextMessages;
    state = state.copyWith(messagesByConversation: updated);
    _notifyShellContentChanged();
    return true;
  }

  void _clearTypingForUser(String conversationId, String userId) {
    if (conversationId.isEmpty || userId.isEmpty) {
      return;
    }
    final existing = state.typingUserIdsByConversation[conversationId];
    if (existing == null || !existing.contains(userId)) {
      return;
    }
    final nextTyping = Map<String, Set<String>>.from(
      state.typingUserIdsByConversation,
    );
    nextTyping[conversationId] = Set<String>.from(existing)..remove(userId);
    state = state.copyWith(typingUserIdsByConversation: nextTyping);
    _cancelTypingExpiry(conversationId, userId);
    _notifyShellContentChanged();
  }

  void _scheduleTypingExpiry(String conversationId, String userId) {
    final normalizedConversationId = conversationId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedConversationId.isEmpty || normalizedUserId.isEmpty) {
      return;
    }
    _cancelTypingExpiry(normalizedConversationId, normalizedUserId);
    final byConversation = _typingExpiryTimers.putIfAbsent(
      normalizedConversationId,
      () => <String, Timer>{},
    );
    byConversation[normalizedUserId] = Timer(const Duration(seconds: 6), () {
      if (!ref.mounted) {
        return;
      }
      _clearTypingForUser(normalizedConversationId, normalizedUserId);
    });
  }

  void _cancelTypingExpiry(String conversationId, String userId) {
    final normalizedConversationId = conversationId.trim();
    final normalizedUserId = userId.trim();
    final timer = _typingExpiryTimers[normalizedConversationId]?.remove(
      normalizedUserId,
    );
    timer?.cancel();
    if (_typingExpiryTimers[normalizedConversationId]?.isEmpty ?? true) {
      _typingExpiryTimers.remove(normalizedConversationId);
    }
  }

  void _cancelAllTypingExpiryTimers() {
    for (final byConversation in _typingExpiryTimers.values) {
      for (final timer in byConversation.values) {
        timer.cancel();
      }
    }
    _typingExpiryTimers.clear();
  }

  void _applyReactionRemoval(
    String conversationId,
    RemovedReactionEvent event,
  ) {
    final messages = state.messagesByConversation[conversationId];
    if (messages == null) {
      return;
    }
    final index = messages.indexWhere((item) => item.id == event.messageId);
    if (index == -1) {
      return;
    }
    final target = messages[index];
    final nextReactions = List<MessageReaction>.from(target.reactions)
      ..removeWhere((item) => _reactionBelongsToUser(item, event.userId));
    final nextMessages = List<ChatMessage>.from(messages);
    nextMessages[index] = target.copyWith(reactions: nextReactions);
    final updated = Map<String, List<ChatMessage>>.from(
      state.messagesByConversation,
    );
    updated[conversationId] = nextMessages;
    state = state.copyWith(messagesByConversation: updated);
    _notifyShellContentChanged();
  }

  void _applyDeletedMessage(DeletedMessageEvent deletedMessage) {
    final messages =
        state.messagesByConversation[deletedMessage.conversationId];
    if (messages == null) {
      return;
    }
    final next = messages
        .map(
          (message) => message.id == deletedMessage.messageId
              ? message.copyWith(
                  deletedAt: deletedMessage.deletedAt,
                  content: '[deleted]',
                )
              : message,
        )
        .toList(growable: false);
    final updated = Map<String, List<ChatMessage>>.from(
      state.messagesByConversation,
    );
    updated[deletedMessage.conversationId] = next;
    state = state.copyWith(messagesByConversation: updated);
    _notifyShellContentChanged();
  }

  void _bindRemotePresenceListener(ChatSession activeSession) {
    _remotePresenceStore = activeSession.remotePresence;
    _remotePresenceByUserId = Map<String, bool>.from(
      _remotePresenceStore!.onlineByUserId.value,
    );
    _remotePresenceListener = () {
      final store = _remotePresenceStore;
      if (store == null || !ref.mounted) {
        return;
      }
      final next = store.onlineByUserId.value;
      final prev = _remotePresenceByUserId;

      for (final entry in next.entries) {
        final uid = entry.key;
        final nextOnline = entry.value;
        if (prev[uid] == nextOnline) {
          continue;
        }
        _applyPresenceUpdate(uid, nextOnline);
      }
      for (final uid in prev.keys) {
        if (!next.containsKey(uid)) {
          _applyPresenceUpdate(uid, false);
        }
      }

      _remotePresenceByUserId = Map<String, bool>.from(next);
    };
    _remotePresenceStore!.onlineByUserId.addListener(_remotePresenceListener!);
    _syncPresenceFromStore();
  }

  void _unbindRemotePresenceListener() {
    final listener = _remotePresenceListener;
    final store = _remotePresenceStore;
    if (listener != null && store != null) {
      store.onlineByUserId.removeListener(listener);
    }
    _remotePresenceListener = null;
    _remotePresenceStore = null;
    _remotePresenceByUserId = const {};
  }

  void _syncPresenceFromStore() {
    final store = _remotePresenceStore;
    if (store == null) {
      return;
    }
    for (final entry in store.onlineByUserId.value.entries) {
      _applyPresenceUpdate(entry.key, entry.value);
    }
  }

  bool _applyPresenceUpdate(String userId, bool isOnline) {
    if (!ref.mounted) {
      return false;
    }

    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return false;
    }

    var usersChanged = false;
    final nextUsers = state.users
        .map((user) {
          if (user.id != normalizedUserId || user.isOnline == isOnline) {
            return user;
          }
          usersChanged = true;
          return _tenantUserWithOnline(user, isOnline);
        })
        .toList(growable: false);

    var conversationsChanged = false;
    final nextConversations = state.conversations
        .map((conversation) {
          var participantsChanged = false;
          final nextParticipants = conversation.participants
              .map((participant) {
                if (participant.user.id != normalizedUserId ||
                    participant.user.isOnline == isOnline) {
                  return participant;
                }
                participantsChanged = true;
                return ConversationParticipant(
                  id: participant.id,
                  userId: participant.userId,
                  conversationId: participant.conversationId,
                  user: _participantUserWithOnline(participant.user, isOnline),
                );
              })
              .toList(growable: false);
          if (!participantsChanged) {
            return conversation;
          }
          conversationsChanged = true;
          return Conversation(
            id: conversation.id,
            tenantId: conversation.tenantId,
            type: conversation.type,
            title: conversation.title,
            createdBy: conversation.createdBy,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt,
            participants: nextParticipants,
            unreadCount: conversation.unreadCount,
            latestMessage: conversation.latestMessage,
            latestMessageId: conversation.latestMessageId,
            latestReaction: conversation.latestReaction,
            messageState: conversation.messageState,
            messageStatusByUserId: conversation.messageStatusByUserId,
          );
        })
        .toList(growable: false);

    if (!usersChanged && !conversationsChanged) {
      return false;
    }

    state = state.copyWith(
      users: usersChanged ? nextUsers : state.users,
      conversations: conversationsChanged
          ? nextConversations
          : state.conversations,
    );
    _notifyShellContentChanged();
    return true;
  }

  TenantUser _tenantUserWithOnline(TenantUser user, bool isOnline) {
    return TenantUser(
      id: user.id,
      tenantId: user.tenantId,
      name: user.name,
      email: user.email,
      role: user.role,
      isOnline: isOnline,
      createdAt: user.createdAt,
      externalUserRole: user.externalUserRole,
      avatarUrl: user.avatarUrl,
      status: user.status,
      accessToken: user.accessToken,
      tokenType: user.tokenType,
      providerUserId: user.providerUserId,
    );
  }

  ConversationParticipantUser _participantUserWithOnline(
    ConversationParticipantUser user,
    bool isOnline,
  ) {
    return ConversationParticipantUser(
      id: user.id,
      username: user.username,
      role: user.role,
      externalUserRole: user.externalUserRole,
      email: user.email,
      avatarUrl: user.avatarUrl,
      status: user.status,
      isOnline: isOnline,
    );
  }

  void _notifyShellContentChanged() {
    _shellContentRevision.value++;
  }

  void _scheduleSlowConversationHint(String conversationId) {
    _slowConversationHintTimer?.cancel();
    _slowConversationHintTimer = Timer(const Duration(milliseconds: 650), () {
      if (!ref.mounted || state.loadingConversationId != conversationId) {
        return;
      }
      state = state.copyWith(slowConversationHintActive: true);
    });
  }

  void _cancelSlowConversationHint() {
    _slowConversationHintTimer?.cancel();
    _slowConversationHintTimer = null;
  }

  String _nameForUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return userId;
    }
    for (final user in state.users) {
      if (user.id == normalized) {
        return user.displayName;
      }
    }
    final selectedConversationId = state.selectedConversationId?.trim() ?? '';
    if (selectedConversationId.isNotEmpty) {
      for (final conversation in state.conversations) {
        if (conversation.id != selectedConversationId) {
          continue;
        }
        for (final participant in conversation.participants) {
          if (participant.user.id == normalized) {
            final username = participant.user.username.trim();
            if (username.isNotEmpty) {
              return username;
            }
          }
        }
      }
    }
    for (final associated in state.associatedUsers) {
      final tenant = _tenantUserForPlatformId(associated.id);
      if (tenant?.id == normalized) {
        return associated.displayName;
      }
    }
    return userId;
  }

  void _snack(String message) => onUserMessage?.call(message);

  void _log(String message, {Object? data}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[HealthMessengerChat] $message${data == null ? '' : ' :: $data'}',
    );
  }

  Future<void> _dispose() async {
    _cancelSlowConversationHint();
    _shellContentRevision.dispose();
    await detachFromSession();
  }
}
