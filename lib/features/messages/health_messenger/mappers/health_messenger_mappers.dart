import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/features/messages/health_messenger/mappers/associated_user_messenger_mapper.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';

/// Maps generic-chat API models to package UI models for [MessengerChatShell].
class HealthMessengerMappers {
  HealthMessengerMappers({
    required this.currentUserId,
    required this.mediaBaseUrl,
    required this.users,
    this.associatedUsers = const [],
  });

  final String currentUserId;
  final String mediaBaseUrl;
  final List<TenantUser> users;
  final List<AssociatedUser> associatedUsers;

  /// Maps a wire id (chat user id or external/provider id) to the tenant chat id.
  String resolveChatUserId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    for (final user in users) {
      if (user.id.trim() == trimmed) {
        return user.id.trim();
      }
      final providerId = user.providerUserId?.trim() ?? '';
      if (providerId.isNotEmpty && providerId == trimmed) {
        return user.id.trim();
      }
    }
    return trimmed;
  }

  String resolveMessageSenderId(ChatMessage message) {
    final direct = message.senderId.trim();
    if (direct.isNotEmpty) {
      return resolveChatUserId(direct);
    }
    final fromSender = message.sender?.id.trim() ?? '';
    if (fromSender.isNotEmpty) {
      return resolveChatUserId(fromSender);
    }
    return '';
  }

  String resolveReactionUserId(MessageReaction reaction) {
    for (final candidate in [
      reaction.userId,
      reaction.user?.id ?? '',
    ]) {
      final resolved = resolveChatUserId(candidate);
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }
    return '';
  }

  String normalizeReactionType(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? '👍' : trimmed;
  }

  List<MessengerMessageReaction> mapMessageReactions(
    List<MessageReaction> reactions,
  ) {
    final byUser = <String, MessengerMessageReaction>{};
    for (final reaction in reactions) {
      final userId = resolveReactionUserId(reaction);
      final reactionType = normalizeReactionType(reaction.reactionType);
      if (userId.isEmpty) {
        continue;
      }
      byUser[userId] = MessengerMessageReaction(
        userId: userId,
        reactionType: reactionType,
      );
    }
    return byUser.values.toList(growable: false);
  }

  bool isMessageFromCurrentUser({required String senderId}) {
    final selfId = currentUserId.trim();
    if (selfId.isEmpty) {
      return false;
    }
    return resolveChatUserId(senderId) == selfId;
  }

  MessengerUser mapTenantUser(TenantUser user) {
    return MessengerUser(
      id: user.id,
      username: user.displayName,
      roleLabel: roleLabelForTenantUser(user),
      email: user.email,
      isOnline: user.isOnline,
      avatarUrl: resolveAvatarUrl(user.avatarUrl),
    );
  }

  List<MessengerUser> mapUiUsers(List<TenantUser> tenantUsers) {
    final mapped = tenantUsers
        .where((user) => user.id != currentUserId)
        .map(mapTenantUser)
        .toList(growable: false);
    mapped.sort((left, right) {
      if (left.isOnline != right.isOnline) {
        return left.isOnline ? -1 : 1;
      }
      return left.username.toLowerCase().compareTo(right.username.toLowerCase());
    });
    return mapped;
  }

  MessengerConversation mapConversation({
    required Conversation conversation,
    required Map<String, int> unreadMap,
    required ConversationOrderSnapshot orderSnapshot,
    required List<ChatMessage> localMessages,
    int fallbackApiRank = 0,
  }) {
    final title = conversationTitle(conversation);
    final localLatest = localMessages.isEmpty ? null : localMessages.last;
    final restLatest = conversation.latestMessage;
    final previewSource = newestChatMessage(localLatest, restLatest);
    final latestReaction = conversation.latestReaction;
    final reactionIsLatest = latestReaction != null &&
        messengerReactionIsLatestInboxActivity(
          reactionCreatedAt: latestReaction.createdAt,
          latestMessageCreatedAt: previewSource?.createdAt,
        );
    final subtitle = previewSource == null
        ? '${conversation.type} conversation'
        : messagePreview(previewSource);
    final activityCandidate =
        newestDateTime(localLatest?.createdAt, restLatest?.createdAt);
    final latestActivityCandidate =
        newestDateTime(activityCandidate, latestReaction?.createdAt);
    final lastActivityAt = latestActivityCandidate != null &&
            latestActivityCandidate.isAfter(conversation.updatedAt)
        ? latestActivityCandidate
        : conversation.updatedAt;
    final others = conversation.participants
        .where(
          (participant) =>
              resolveChatUserId(participant.user.id) !=
              resolveChatUserId(currentUserId),
        )
        .toList();
    final isGroup = isGroupConversation(conversation);
    final peerUsers = mapConversationPeerUsers(conversation);
    // Direct chats only — groups use the shared Users icon in the list.
    final directAvatarUrl = !isGroup && others.length == 1
        ? avatarForParticipant(others.first)
        : null;

    return MessengerConversation(
      id: conversation.id,
      title: title,
      subtitle: subtitle,
      avatarLabel: initials(title),
      createdAt: conversation.createdAt,
      lastActivityAt: lastActivityAt,
      isGlobal: conversation.isGlobal,
      isGroup: isGroup,
      unreadCount: unreadMap[conversation.id] ?? 0,
      avatarUrl: directAvatarUrl,
      isOnline: peerUsers.any((user) => user.isOnline) ||
          others.any((participant) => participant.user.isOnline),
      peerUsers: peerUsers,
      apiRank: orderSnapshot.apiRank[conversation.id] ?? fallbackApiRank,
      promotedAt: orderSnapshot.promotedAt[conversation.id],
      latestReaction: reactionIsLatest
          ? MessengerConversationLatestReaction(
              chatUserId: resolveChatUserId(latestReaction.chatUserId),
              reactionType: normalizeReactionType(latestReaction.reactionType),
              userName: displayNameForReaction(conversation, latestReaction),
              createdAt: latestReaction.createdAt,
            )
          : null,
    );
  }

  /// True when the API marks the conversation as a group, or it clearly has
  /// multiple peers under a titled care-team thread.
  static bool isGroupConversation(Conversation conversation) {
    final type = conversation.type.trim().toUpperCase();
    if (type == 'GROUP' || type == 'GROUPS') {
      return true;
    }
    if (type == 'DIRECT' || type == 'SUPPORT' || conversation.isGlobal) {
      return false;
    }
    final titled = conversation.title?.trim().isNotEmpty ?? false;
    return titled && conversation.participants.length > 2;
  }

  List<MessengerUser> mapConversationPeerUsers(Conversation conversation) {
    final selfChatId = resolveChatUserId(currentUserId);
    final peers = <MessengerUser>[];
    for (final participant in conversation.participants) {
      final participantChatId = resolveChatUserId(participant.user.id);
      if (participantChatId.isEmpty || participantChatId == selfChatId) {
        continue;
      }
      peers.add(mapConversationPeerUser(participant));
    }
    if (peers.isNotEmpty) {
      return peers;
    }
    if (isGroupConversation(conversation)) {
      return const [];
    }

    final title = conversationTitle(conversation);
    final titleMatches = <AssociatedUser>[];
    for (final associated in associatedUsers) {
      final mapped = AssociatedUserMessengerMapper.toMessengerUser(associated);
      if (_associatedUserMatchesConversationTitle(mapped, title, conversation)) {
        titleMatches.add(associated);
      }
    }
    if (titleMatches.length != 1) {
      return const [];
    }
    final associated = titleMatches.first;
    final mapped = AssociatedUserMessengerMapper.toMessengerUser(associated);
    for (final tenant in users) {
      final providerId = tenant.providerUserId?.trim() ?? '';
      if (providerId == associated.id.trim()) {
        return [mapTenantUser(tenant)];
      }
    }
    return [
      MessengerUser(
        id: mapped.id,
        externalUserId: resolveChatUserId(associated.id),
        username: mapped.username,
        roleLabel: mapped.roleLabel,
        email: mapped.email,
        isOnline: mapped.isOnline,
        avatarUrl: mapped.avatarUrl,
      ),
    ];
  }

  bool _associatedUserMatchesConversationTitle(
    MessengerUser user,
    String title,
    Conversation conversation,
  ) {
    final username = user.username.trim().toLowerCase();
    final normalizedTitle = title.trim().toLowerCase();
    if (username.isEmpty || normalizedTitle.isEmpty) {
      return false;
    }
    final previewSource = conversation.latestMessage;
    final subtitle = previewSource == null
        ? ''
        : messagePreview(previewSource).trim().toLowerCase();
    final display = user.username
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part.toLowerCase())
        .join(' ');
    return normalizedTitle.contains(username) ||
        (display.isNotEmpty && normalizedTitle.contains(display)) ||
        subtitle.contains(username) ||
        (display.isNotEmpty && subtitle.contains(display));
  }

  MessengerChatMessage mapMessage(ChatMessage message) {
    final body = message.content.trim();
    final uiType = mapUiMessageType(message.type);
    final uiAttachments = messengerAttachmentsFromChatMessage(
      message,
      fallbackType: uiType,
      mediaBaseOrigin: mediaBaseUrl.isEmpty ? null : mediaBaseUrl,
    );
    final attachmentUrl =
        uiAttachments.isEmpty ? '' : uiAttachments.first.url.trim();

    late final String content;
    late final String? caption;

    switch (message.type) {
      case MessageType.image:
      case MessageType.voice:
      case MessageType.video:
      case MessageType.file:
        if (attachmentUrl.isNotEmpty) {
          content = attachmentUrl;
          caption = body.isEmpty ? null : body;
        } else {
          content = body.isEmpty ? messagePreview(message) : body;
          caption = null;
        }
      case MessageType.text:
      case MessageType.link:
      case MessageType.other:
        content = body.isEmpty ? messagePreview(message) : body;
        caption = null;
    }

    return MessengerChatMessage(
      id: message.id,
      senderId: resolveMessageSenderId(message),
      senderLabel: senderName(message),
      type: uiType,
      content: content,
      caption: caption,
      attachments: uiAttachments,
      createdAt: message.createdAt,
      isDeleted: message.isDeleted,
      deliveryStatus: deliveryStatusFor(message),
      reactions: mapMessageReactions(message.reactions),
      senderAvatarUrl: avatarForUser(message.senderId),
      quotedReply: quotedReplyFromChat(message),
    );
  }

  String conversationTitle(Conversation conversation) {
    final explicitTitle = conversation.title?.trim() ?? '';
    if (explicitTitle.isNotEmpty) {
      return explicitTitle;
    }

    final others = conversation.participants
        .where(
          (participant) =>
              resolveChatUserId(participant.user.id) !=
              resolveChatUserId(currentUserId),
        )
        .map((participant) => participant.user.username)
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (others.isNotEmpty) {
      if (others.length <= 2) {
        return others.join(', ');
      }
      return '${others[0]}, ${others[1]}…';
    }

    return conversation.type.toUpperCase();
  }

  String messagePreview(ChatMessage message) {
    return messengerConversationPreview(
      message,
      mediaBaseOrigin: mediaBaseUrl.isEmpty ? null : mediaBaseUrl,
    );
  }

  MessengerUser mapConversationPeerUser(ConversationParticipant participant) {
    final mapped = mapParticipantUser(participant.user);
    return MessengerUser(
      id: mapped.id,
      username: mapped.username,
      roleLabel: roleLabelForParticipant(participant),
      email: mapped.email,
      isOnline: mapped.isOnline,
      avatarUrl: avatarForParticipant(participant),
    );
  }

  MessengerUser mapParticipantUser(ConversationParticipantUser user) {
    return MessengerUser(
      id: user.id,
      username: user.username,
      roleLabel: roleLabelForParticipantUser(user),
      email: user.email?.trim() ?? '',
      isOnline: user.isOnline,
      avatarUrl: resolveAvatarUrl(user.avatarUrl),
    );
  }

  /// Prefer VCare associated-user `careTeamRole` (then `userType`), then raw
  /// chat `externalUserRole`, then the collapsed [AppRole] label.
  String roleLabelForParticipant(ConversationParticipant participant) {
    final fromAssociated = associatedRoleFor(
      chatUserId: participant.user.id,
      fallbackChatUserId: participant.userId,
      email: participant.user.email,
    );
    if (fromAssociated != null) {
      return fromAssociated;
    }
    return roleLabelForParticipantUser(participant.user);
  }

  String roleLabelForParticipantUser(ConversationParticipantUser user) {
    final raw = user.externalUserRole?.trim();
    if (raw != null &&
        raw.isNotEmpty &&
        !parseRoleIgnoresMembershipLabel(raw)) {
      return AssociatedUserMessengerMapper.humanizeRole(raw);
    }
    return user.role.label;
  }

  String roleLabelForTenantUser(TenantUser user) {
    final fromAssociated = associatedRoleForPlatformId(user.providerUserId) ??
        associatedRoleForEmail(user.email);
    if (fromAssociated != null) {
      return fromAssociated;
    }
    final raw = user.externalUserRole?.trim();
    if (raw != null &&
        raw.isNotEmpty &&
        !parseRoleIgnoresMembershipLabel(raw)) {
      return AssociatedUserMessengerMapper.humanizeRole(raw);
    }
    return user.role.label;
  }

  String? associatedRoleFor({
    required String chatUserId,
    String? fallbackChatUserId,
    String? email,
  }) {
    for (final candidate in [chatUserId, fallbackChatUserId ?? '']) {
      final trimmed = candidate.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      for (final user in users) {
        if (user.id != trimmed) {
          continue;
        }
        final fromPlatform = associatedRoleForPlatformId(user.providerUserId);
        if (fromPlatform != null) {
          return fromPlatform;
        }
        final fromEmail = associatedRoleForEmail(user.email);
        if (fromEmail != null) {
          return fromEmail;
        }
      }
    }
    return associatedRoleForEmail(email);
  }

  String? associatedRoleForPlatformId(String? platformId) {
    final normalized = platformId?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    for (final user in associatedUsers) {
      if (user.id.trim().toLowerCase() != normalized) {
        continue;
      }
      final role = AssociatedUserMessengerMapper.displayRoleFor(user).trim();
      if (role.isNotEmpty) {
        return role;
      }
    }
    return null;
  }

  String? associatedRoleForEmail(String? email) {
    final normalized = email?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    for (final user in associatedUsers) {
      if (user.email.trim().toLowerCase() != normalized) {
        continue;
      }
      final role = AssociatedUserMessengerMapper.displayRoleFor(user).trim();
      if (role.isNotEmpty) {
        return role;
      }
    }
    return null;
  }

  /// Absolutizes relative chat media paths and drops values that cannot be
  /// loaded as network images (storage keys, blank strings, etc.).
  String? resolveAvatarUrl(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final absolute = messengerAbsoluteMediaUrl(
      trimmed,
      baseOrigin: mediaBaseUrl.isEmpty ? null : mediaBaseUrl,
    );
    if (absolute.isEmpty || !messengerMediaSourceIsNetwork(absolute)) {
      return null;
    }
    return absolute;
  }

  String? avatarForParticipant(ConversationParticipant participant) {
    final associatedAvatar = associatedAvatarFor(
      chatUserId: participant.user.id,
      fallbackChatUserId: participant.userId,
      email: participant.user.email,
    );
    if (associatedAvatar != null) {
      return associatedAvatar;
    }
    final participantAvatar = resolveAvatarUrl(participant.user.avatarUrl);
    if (participantAvatar != null) {
      return participantAvatar;
    }
    return avatarForUser(participant.user.id) ??
        avatarForUser(participant.userId);
  }

  String? avatarForUser(String userId) {
    for (final user in users) {
      if (user.id == userId) {
        final avatar = resolveAvatarUrl(user.avatarUrl);
        if (avatar != null) {
          return avatar;
        }
        final fromAssociated = associatedAvatarForPlatformId(
          user.providerUserId,
        );
        if (fromAssociated != null) {
          return fromAssociated;
        }
        return associatedAvatarForEmail(user.email);
      }
    }
    return null;
  }

  String? associatedAvatarFor({
    required String chatUserId,
    String? fallbackChatUserId,
    String? email,
  }) {
    for (final candidate in [chatUserId, fallbackChatUserId ?? '']) {
      final trimmed = candidate.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      for (final user in users) {
        if (user.id != trimmed) {
          continue;
        }
        final fromPlatform = associatedAvatarForPlatformId(user.providerUserId);
        if (fromPlatform != null) {
          return fromPlatform;
        }
        final fromEmail = associatedAvatarForEmail(user.email);
        if (fromEmail != null) {
          return fromEmail;
        }
      }
    }
    return associatedAvatarForEmail(email);
  }

  String? associatedAvatarForPlatformId(String? platformId) {
    final normalized = platformId?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    for (final user in associatedUsers) {
      if (user.id.trim().toLowerCase() != normalized) {
        continue;
      }
      return resolveAvatarUrl(user.profilePhotoUrl);
    }
    return null;
  }

  String? associatedAvatarForEmail(String? email) {
    final normalized = email?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    for (final user in associatedUsers) {
      if (user.email.trim().toLowerCase() != normalized) {
        continue;
      }
      return resolveAvatarUrl(user.profilePhotoUrl);
    }
    return null;
  }

  String senderName(ChatMessage message) {
    final sender = message.sender;
    if (sender != null && (sender.name?.trim().isNotEmpty ?? false)) {
      return sender.name!.trim();
    }
    for (final user in users) {
      if (user.id == message.senderId) {
        return user.displayName;
      }
    }
    return message.senderId;
  }

  String displayNameForReaction(
    Conversation conversation,
    LatestReaction reaction,
  ) {
    if (reaction.userName.trim().isNotEmpty) {
      return reaction.userName.trim();
    }
    final chatUserId = resolveChatUserId(reaction.chatUserId);
    for (final participant in conversation.participants) {
      if (participant.user.id == chatUserId) {
        return participant.user.username;
      }
    }
    return chatUserId.isEmpty ? reaction.chatUserId : chatUserId;
  }

  MessengerDeliveryStatus deliveryStatusFor(ChatMessage message) {
    if (currentUserId.isEmpty) {
      return MessengerDeliveryStatus.none;
    }
    return messengerDeliveryStatusFor(
      message,
      currentUserId: currentUserId,
    );
  }

  MessengerQuotedMessage? quotedReplyFromChat(ChatMessage message) {
    final reply = message.replyTo;
    if (reply == null) {
      return null;
    }
    final id = reply.id.trim();
    if (id.isEmpty) {
      return null;
    }
    final preview = reply.content.trim().isEmpty
        ? mapUiMessageType(reply.type).name
        : reply.content.trim();
    return MessengerQuotedMessage(
      messageId: id,
      senderLabel: replySenderLabel(reply),
      preview: preview,
      messageType: mapUiMessageType(reply.type),
    );
  }

  String replySenderLabel(ReplyToMessage reply) {
    final senderName = reply.sender?.name?.trim() ?? '';
    if (senderName.isNotEmpty) {
      return senderName;
    }
    for (final user in users) {
      if (user.id == reply.senderId) {
        return user.displayName;
      }
    }
    return reply.senderId;
  }

  static MessengerMessageType mapUiMessageType(MessageType type) {
    switch (type) {
      case MessageType.image:
        return MessengerMessageType.image;
      case MessageType.voice:
        return MessengerMessageType.voice;
      case MessageType.video:
        return MessengerMessageType.video;
      case MessageType.file:
        return MessengerMessageType.file;
      case MessageType.text:
      case MessageType.link:
      case MessageType.other:
        return MessengerMessageType.text;
    }
  }

  static ChatMessage? newestChatMessage(ChatMessage? a, ChatMessage? b) {
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return a.createdAt.isBefore(b.createdAt) ? b : a;
  }

  static DateTime? newestDateTime(DateTime? a, DateTime? b) {
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return a.isBefore(b) ? b : a;
  }

  static String initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
