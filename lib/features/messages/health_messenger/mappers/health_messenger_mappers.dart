import 'package:health_messenger_ui/lib/health_messenger_ui.dart';

/// Maps generic-chat API models to package UI models for [MessengerChatShell].
class HealthMessengerMappers {
  HealthMessengerMappers({
    required this.currentUserId,
    required this.mediaBaseUrl,
    required this.users,
  });

  final String currentUserId;
  final String mediaBaseUrl;
  final List<TenantUser> users;

  MessengerUser mapTenantUser(TenantUser user) {
    return MessengerUser(
      id: user.id,
      username: user.displayName,
      roleLabel: user.role.label,
      email: user.email,
      isOnline: user.isOnline,
      avatarUrl: user.avatarUrl,
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
        (previewSource == null ||
            latestReaction.createdAt.isAfter(previewSource.createdAt));
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
        .where((participant) => participant.user.id != currentUserId)
        .toList();
    final isGroup = isGroupConversation(conversation);
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
      isOnline: others.any((participant) => participant.user.isOnline),
      peerUsers:
          others.map(mapConversationPeerUser).toList(growable: false),
      apiRank: orderSnapshot.apiRank[conversation.id] ?? fallbackApiRank,
      promotedAt: orderSnapshot.promotedAt[conversation.id],
      latestReaction: reactionIsLatest
          ? MessengerConversationLatestReaction(
              chatUserId: latestReaction.chatUserId,
              reactionType: latestReaction.reactionType,
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
      senderId: message.senderId,
      senderLabel: senderName(message),
      type: uiType,
      content: content,
      caption: caption,
      attachments: uiAttachments,
      createdAt: message.createdAt,
      isDeleted: message.isDeleted,
      deliveryStatus: deliveryStatusFor(message),
      reactions: message.reactions
          .map(
            (reaction) => MessengerMessageReaction(
              userId: reaction.userId,
              reactionType: reaction.reactionType,
            ),
          )
          .toList(),
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
        .where((participant) => participant.user.id != currentUserId)
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
      roleLabel: mapped.roleLabel,
      email: mapped.email,
      isOnline: mapped.isOnline,
      avatarUrl: avatarForParticipant(participant),
    );
  }

  MessengerUser mapParticipantUser(ConversationParticipantUser user) {
    return MessengerUser(
      id: user.id,
      username: user.username,
      roleLabel: user.role.label,
      email: user.email?.trim() ?? '',
      isOnline: user.isOnline,
      avatarUrl: user.avatarUrl,
    );
  }

  String? avatarForParticipant(ConversationParticipant participant) {
    final participantAvatar = participant.user.avatarUrl?.trim();
    if (participantAvatar != null && participantAvatar.isNotEmpty) {
      return participantAvatar;
    }
    return avatarForUser(participant.user.id) ??
        avatarForUser(participant.userId);
  }

  String? avatarForUser(String userId) {
    for (final user in users) {
      if (user.id == userId) {
        return user.avatarUrl;
      }
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
    for (final participant in conversation.participants) {
      if (participant.user.id == reaction.chatUserId) {
        return participant.user.username;
      }
    }
    return reaction.chatUserId;
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
