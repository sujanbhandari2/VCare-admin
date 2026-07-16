import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health_messenger_ui/lib/health_messenger_push.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vcare_admin/features/messages/health_messenger/mappers/associated_user_messenger_mapper.dart';
import 'package:vcare_admin/features/messages/health_messenger/mappers/health_messenger_mappers.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_bootstrap_config.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_state.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_provider.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';
import 'package:vcare_admin/features/users/presentation/providers/associated_users_repository_provider.dart';

part 'health_messenger_chat_notifier.g.dart';

@riverpod
class HealthMessengerChatNotifier extends _$HealthMessengerChatNotifier {
  static const String _draftDirectPrefix = '__pending_direct__:';

  StreamSubscription<ChatSocketEvent>? _socketSubscription;
  StreamSubscription<MessengerPushEvent>? _pushEventsSubscription;
  VoidCallback? _remotePresenceListener;
  Timer? _slowConversationHintTimer;
  bool _attachedToSession = false;

  VoidCallback? onRequestScrollToBottom;
  void Function(String message)? onUserMessage;

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
      );

  @override
  HealthMessengerChatState build() {
    ref.onDispose(_dispose);
    return const HealthMessengerChatState();
  }

  Future<void> bootstrap() async {
    if (_attachedToSession && _session?.sessionAuth != null) {
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
        final error = sessionState.bootstrapError ??
            Exception('Chat session is not available.');
        state = state.copyWith(
          bootstrapError: error,
          isBootstrapping: false,
          initialBootstrapLoad: false,
        );
        _snack('Chat could not start.');
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
      await refreshAll(selectFirstConversation: true);
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
      _snack('Chat could not start. Check logs and configuration.');
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
      isSocketConnected: false,
    );
    _attachedToSession = true;
    _bindRemotePresenceListener(activeSession);
  }

  Future<void> detachFromSession() async {
    _cancelSlowConversationHint();
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _pushEventsSubscription?.cancel();
    _pushEventsSubscription = null;
    _unbindRemotePresenceListener();
    _attachedToSession = false;
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

      final usersFuture = client.getUsers(auth);
      final associatedUsersFuture = _loadAssociatedUsers();
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
        currentUser: selectedCurrentUser ??
            state.currentUser ??
            (users.isNotEmpty ? users.first : null),
        isSuggestedUsersLoading: false,
      );

      if (!state.isSocketConnected) {
        await ensureSocketConnected();
      }
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
    final result = await repository.fetchAssociatedUsers();

    if (!ref.mounted) {
      return;
    }

    result.when(
      success: (page) {
        final currentPlatformUserId = _currentPlatformUserId.trim().toLowerCase();
        final filtered = page.users
            .where(
              (user) =>
                  user.id.trim().toLowerCase() != currentPlatformUserId,
            )
            .toList(growable: false);
        state = state.copyWith(associatedUsers: filtered);
      },
      failure: (error) {
        _log(
          'Associated users load failed',
          data: {'error': error.toString()},
        );
      },
    );
  }

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
      final previousConversationId = state.selectedConversationId;
      if (previousConversationId != null &&
          !isDraftConversationId(previousConversationId)) {
        try {
          await chatSession.leaveConversation(previousConversationId);
        } catch (_) {}
      }
      state = state.copyWith(
        clearSelectedConversationId: true,
        clearLoadingConversationId: true,
        slowConversationHintActive: false,
        clearComposerReplyDraft: true,
      );
      return;
    }

    // Ignore repeated taps on the same conversation while it is still loading.
    final loadingId = state.loadingConversationId?.trim() ?? '';
    if (loadingId.isNotEmpty) {
      return;
    }

    _cancelSlowConversationHint();
    state = state.copyWith(
      selectedConversationId: conversationId,
      loadingConversationId: conversationId,
      slowConversationHintActive: false,
      clearComposerReplyDraft: true,
    );

    if (isDraftConversationId(conversationId)) {
      state = state.copyWith(clearLoadingConversationId: true);
      return;
    }

    _scheduleSlowConversationHint(conversationId);

    try {
      await _loadMessages(conversationId);

      var connected = state.isSocketConnected;
      if (!connected && tryReconnect) {
        connected = await ensureSocketConnected();
      }
      if (!connected) {
        return;
      }

      await chatSession.joinConversation(conversationId);
    } catch (error, stackTrace) {
      _log(
        'Select conversation failed',
        data: {
          'conversationId': conversationId,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      _snack('Could not open conversation.');
    } finally {
      _cancelSlowConversationHint();
      if (ref.mounted && state.loadingConversationId == conversationId) {
        state = state.copyWith(
          clearLoadingConversationId: true,
          slowConversationHintActive: false,
        );
      }
    }
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
      return;
    }

    state = state.copyWith(suggestedPeopleOpeningUserId: user.id.trim());
    try {
      final platformPeerId = user.id.trim();
      final peerTenantUser = _tenantUserForPlatformId(platformPeerId);
      final peerChatUserId = peerTenantUser?.id.trim() ?? '';

      if (peerChatUserId.isNotEmpty) {
        final existing = _findDirectConversation(currentUser.id, peerChatUserId);
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
        return;
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
        final realId = await _materializeDraftDirectConversation(conversationId);
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
      _upsertMessage(conversationId, created);
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
    if (client == null || conversationId == null) {
      return;
    }

    state = state.copyWith(
      pendingReactionRequests: state.pendingReactionRequests + 1,
    );
    try {
      final reaction = await client.reactToMessage(
        conversationId: conversationId,
        messageId: messageId,
        reactionType: reactionType,
      );
      _applyReaction(conversationId, reaction);
    } catch (error) {
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

    state = state.copyWith(
      pendingReactionRequests: state.pendingReactionRequests + 1,
    );
    try {
      final removed = await client.removeReaction(
        conversationId: conversationId,
        messageId: messageId,
      );
      if (removed) {
        _applyReactionRemoval(
          conversationId,
          RemovedReactionEvent(
            messageId: messageId,
            conversationId: conversationId,
            userId: currentUser.id,
          ),
        );
      }
    } catch (error) {
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

    try {
      final result = await actions.deleteMessage(
        auth,
        conversationId: conversationId,
        messageId: messageId,
        userId: currentUser.id,
      );
      _applyDeletedMessage(
        DeletedMessageEvent(
          messageId: result.messageId,
          conversationId: result.conversationId,
          deletedAt: result.deletedAt ?? DateTime.now().toUtc(),
          userId: currentUser.id,
        ),
      );
    } catch (error) {
      _snack('Could not delete the message.');
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    final actions = _hostActions;
    final conversationId = state.selectedConversationId;
    final trimmed = newText.trim();
    if (actions == null ||
        conversationId == null ||
        isDraftConversationId(conversationId) ||
        trimmed.isEmpty) {
      return;
    }

    try {
      final edited = await actions.editMessage(
        conversationId: conversationId,
        messageId: messageId,
        content: trimmed,
      );
      _upsertMessage(conversationId, edited);
    } catch (error) {
      _snack('Could not edit the message.');
    }
  }

  Future<void> deleteConversation(MessengerConversation conversationView) async {
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
      if (participantChatId == platformId ||
          participantUserId == platformId) {
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

  Future<void> markSeen(String messageId) async {
    final client = _client;
    final auth = _sessionAuth;
    final conversationId = state.selectedConversationId;
    if (client == null ||
        auth == null ||
        conversationId == null ||
        isDraftConversationId(conversationId)) {
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
  }

  void setMediaUploading(bool value) {
    state = state.copyWith(isMediaUploading: value);
  }

  void upsertMediaMessage(String conversationId, ChatMessage message) {
    _upsertMessage(conversationId, message);
    _session?.inbox.bumpConversation(conversationId);
  }

  bool canDeleteMessage(MessengerChatMessage message) {
    return message.senderId == state.currentUser?.id && !message.isDeleted;
  }

  bool canEditMessengerMessage(MessengerChatMessage message) {
    return message.senderId == state.currentUser?.id &&
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

  List<MessengerUser> get uiUsers =>
      AssociatedUserMessengerMapper.toMessengerUsers(state.associatedUsers);

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
    return ids
        .map(
          (id) => MessengerTypingUser(
            userId: id,
            displayLabel: _nameForUser(id),
          ),
        )
        .toList(growable: false);
  }

  Future<bool> ensureSocketConnected() async {
    final session = _session;
    if (session == null) {
      return false;
    }
    if (state.isSocketConnected) {
      return true;
    }
    try {
      await session.reconnectSocket();
      if (ref.mounted) {
        state = state.copyWith(isSocketConnected: true);
      }
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(isSocketConnected: false);
      }
      return false;
    }
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
    if (conversationId.trim().isEmpty ||
        isDraftConversationId(conversationId)) {
      return;
    }
    final chatSession = _session;
    if (chatSession != null) {
      try {
        await chatSession.leaveConversation(conversationId);
      } catch (_) {}
    }
    if (state.selectedConversationId == conversationId) {
      await selectConversation('');
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
      case ChatSocketEventType.disconnected:
      case ChatSocketEventType.error:
        state = state.copyWith(isSocketConnected: false);
      case ChatSocketEventType.messageReceived:
        final message = event.message;
        if (message != null) {
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
          final nextTyping = Map<String, Set<String>>.from(
            state.typingUserIdsByConversation,
          );
          nextTyping
              .putIfAbsent(typing.conversationId, () => <String>{})
              .add(typing.userId);
          state = state.copyWith(typingUserIdsByConversation: nextTyping);
        }
      case ChatSocketEventType.userStoppedTyping:
        final typing = event.typing;
        if (typing != null &&
            typing.userId.isNotEmpty &&
            typing.conversationId.isNotEmpty) {
          final nextTyping = Map<String, Set<String>>.from(
            state.typingUserIdsByConversation,
          );
          nextTyping[typing.conversationId]?.remove(typing.userId);
          state = state.copyWith(typingUserIdsByConversation: nextTyping);
        }
      case ChatSocketEventType.messageDelivered:
      case ChatSocketEventType.messageRead:
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
    final existing = state.messagesByConversation[conversationId] ?? const [];
    final next = List<ChatMessage>.from(existing);
    final index = next.indexWhere((item) => item.id == message.id);
    if (index == -1) {
      next.add(message);
    } else {
      next[index] = mergeMessageDeliveryReadSnapshot(
        next[index],
        _coalesceDeletedMessageOnUpsert(next[index], message),
      );
    }
    next.sort((left, right) => left.createdAt.compareTo(right.createdAt));

    final nextMessages = Map<String, List<ChatMessage>>.from(
      state.messagesByConversation,
    );
    nextMessages[conversationId] = next;
    state = state.copyWith(messagesByConversation: nextMessages);
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

  void _applyReaction(String conversationId, MessageReaction reaction) {
    final messages = state.messagesByConversation[conversationId];
    if (messages == null) {
      return;
    }
    final index = messages.indexWhere((item) => item.id == reaction.messageId);
    if (index == -1) {
      return;
    }
    final target = messages[index];
    final nextReactions = List<MessageReaction>.from(target.reactions)
      ..removeWhere((item) => item.userId == reaction.userId)
      ..add(reaction);
    final nextMessages = List<ChatMessage>.from(messages);
    nextMessages[index] = target.copyWith(reactions: nextReactions);
    final updated = Map<String, List<ChatMessage>>.from(
      state.messagesByConversation,
    );
    updated[conversationId] = nextMessages;
    state = state.copyWith(messagesByConversation: updated);
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
      ..removeWhere((item) => item.userId == event.userId);
    final nextMessages = List<ChatMessage>.from(messages);
    nextMessages[index] = target.copyWith(reactions: nextReactions);
    final updated = Map<String, List<ChatMessage>>.from(
      state.messagesByConversation,
    );
    updated[conversationId] = nextMessages;
    state = state.copyWith(messagesByConversation: updated);
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
  }

  void _bindRemotePresenceListener(ChatSession activeSession) {
    _remotePresenceListener = () {
      // Presence updates flow through conversation participants on refresh.
    };
    activeSession.remotePresence.onlineByUserId
        .addListener(_remotePresenceListener!);
  }

  void _unbindRemotePresenceListener() {
    final listener = _remotePresenceListener;
    final activeSession = _session;
    if (listener != null && activeSession != null) {
      activeSession.remotePresence.onlineByUserId.removeListener(listener);
    }
    _remotePresenceListener = null;
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
    for (final user in state.users) {
      if (user.id == userId) {
        return user.displayName;
      }
    }
    return userId;
  }

  void _snack(String message) => onUserMessage?.call(message);

  void _log(String message, {Object? data}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[HealthMessengerChat] $message${data == null ? '' : ' :: $data'}');
  }

  Future<void> _dispose() async {
    _cancelSlowConversationHint();
    await detachFromSession();
  }
}
