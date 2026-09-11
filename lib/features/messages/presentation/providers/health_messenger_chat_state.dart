import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';

/// Tracks a message being edited in the thread composer.
class MessengerComposerEditDraft {
  const MessengerComposerEditDraft({required this.messageId});

  final String messageId;
}

class HealthMessengerChatState {
  const HealthMessengerChatState({
    this.bootstrapError,
    this.isBootstrapping = false,
    this.initialBootstrapLoad = false,
    this.isRefreshing = false,
    this.isConversationListLoading = false,
    this.isSuggestedUsersLoading = false,
    this.isSending = false,
    this.isMediaUploading = false,
    this.isLoggingOut = false,
    this.isCreatingGroup = false,
    this.isSocketConnected = false,
    this.pendingReactionRequests = 0,
    this.suggestedPeopleOpeningUserId = '',
    this.selectedConversationId,
    this.loadingConversationId,
    this.slowConversationHintActive = false,
    this.currentUser,
    this.users = const [],
    this.associatedUsers = const [],
    this.conversations = const [],
    this.messagesByConversation = const {},
    this.typingUserIdsByConversation = const {},
    this.composerReplyDraft,
    this.composerEditDraft,
  });

  final Object? bootstrapError;
  final bool isBootstrapping;
  final bool initialBootstrapLoad;
  final bool isRefreshing;
  final bool isConversationListLoading;
  final bool isSuggestedUsersLoading;
  final bool isSending;
  final bool isMediaUploading;
  final bool isLoggingOut;
  final bool isCreatingGroup;
  final bool isSocketConnected;
  final int pendingReactionRequests;
  final String suggestedPeopleOpeningUserId;
  final String? selectedConversationId;
  final String? loadingConversationId;
  final bool slowConversationHintActive;
  final TenantUser? currentUser;
  final List<TenantUser> users;
  final List<AssociatedUser> associatedUsers;
  final List<Conversation> conversations;
  final Map<String, List<ChatMessage>> messagesByConversation;
  final Map<String, Set<String>> typingUserIdsByConversation;
  final MessengerComposerReplyDraft? composerReplyDraft;
  final MessengerComposerEditDraft? composerEditDraft;

  /// True only while the conversation that is currently open fetches messages.
  ///
  /// Both ids must be present and equal. Comparing the raw fields would report
  /// `null == null` as "loading", which leaves a reopened thread on the
  /// package loading placeholder (empty messages + loading) with nothing left
  /// to clear it.
  bool get isSelectedConversationLoading {
    final loadingId = loadingConversationId?.trim() ?? '';
    final selectedId = selectedConversationId?.trim() ?? '';
    return loadingId.isNotEmpty && loadingId == selectedId;
  }

  /// True only before a session user exists — host full-screen spinner.
  bool get showPreSessionConnectingShimmer =>
      bootstrapError == null &&
      (isBootstrapping || initialBootstrapLoad) &&
      currentUser == null;

  /// Kept for callers; prefer package [isListPaneRefreshing] once the shell mounts.
  bool get showInitialChatShimmer => initialBootstrapLoad;

  /// Refresh is shown inline by the package list — never stack a second overlay.
  bool get showRefreshingChatShimmer => false;

  /// Blocking host overlay for destructive / global ops only.
  /// Conversation open / inbox refresh / send use package or composer loaders.
  bool get showFullScreenLoader => isLoggingOut;

  HealthMessengerChatState copyWith({
    Object? bootstrapError,
    bool clearBootstrapError = false,
    bool? isBootstrapping,
    bool? initialBootstrapLoad,
    bool? isRefreshing,
    bool? isConversationListLoading,
    bool? isSuggestedUsersLoading,
    bool? isSending,
    bool? isMediaUploading,
    bool? isLoggingOut,
    bool? isCreatingGroup,
    bool? isSocketConnected,
    int? pendingReactionRequests,
    String? suggestedPeopleOpeningUserId,
    String? selectedConversationId,
    bool clearSelectedConversationId = false,
    String? loadingConversationId,
    bool clearLoadingConversationId = false,
    bool? slowConversationHintActive,
    TenantUser? currentUser,
    List<TenantUser>? users,
    List<AssociatedUser>? associatedUsers,
    List<Conversation>? conversations,
    Map<String, List<ChatMessage>>? messagesByConversation,
    Map<String, Set<String>>? typingUserIdsByConversation,
    MessengerComposerReplyDraft? composerReplyDraft,
    bool clearComposerReplyDraft = false,
    MessengerComposerEditDraft? composerEditDraft,
    bool clearComposerEditDraft = false,
  }) {
    return HealthMessengerChatState(
      bootstrapError: clearBootstrapError
          ? null
          : bootstrapError ?? this.bootstrapError,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      initialBootstrapLoad: initialBootstrapLoad ?? this.initialBootstrapLoad,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isConversationListLoading:
          isConversationListLoading ?? this.isConversationListLoading,
      isSuggestedUsersLoading:
          isSuggestedUsersLoading ?? this.isSuggestedUsersLoading,
      isSending: isSending ?? this.isSending,
      isMediaUploading: isMediaUploading ?? this.isMediaUploading,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      isCreatingGroup: isCreatingGroup ?? this.isCreatingGroup,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      pendingReactionRequests:
          pendingReactionRequests ?? this.pendingReactionRequests,
      suggestedPeopleOpeningUserId:
          suggestedPeopleOpeningUserId ?? this.suggestedPeopleOpeningUserId,
      selectedConversationId: clearSelectedConversationId
          ? null
          : selectedConversationId ?? this.selectedConversationId,
      loadingConversationId: clearLoadingConversationId
          ? null
          : loadingConversationId ?? this.loadingConversationId,
      slowConversationHintActive:
          slowConversationHintActive ?? this.slowConversationHintActive,
      currentUser: currentUser ?? this.currentUser,
      users: users ?? this.users,
      associatedUsers: associatedUsers ?? this.associatedUsers,
      conversations: conversations ?? this.conversations,
      messagesByConversation:
          messagesByConversation ?? this.messagesByConversation,
      typingUserIdsByConversation:
          typingUserIdsByConversation ?? this.typingUserIdsByConversation,
      composerReplyDraft: clearComposerReplyDraft
          ? null
          : composerReplyDraft ?? this.composerReplyDraft,
      composerEditDraft: clearComposerEditDraft
          ? null
          : composerEditDraft ?? this.composerEditDraft,
    );
  }
}
