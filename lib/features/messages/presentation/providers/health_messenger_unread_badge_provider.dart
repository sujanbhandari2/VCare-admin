import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_provider.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_state.dart';

part 'health_messenger_unread_badge_provider.g.dart';

/// Whether any conversation has unread messages for the Messages tab red dot.
///
/// Bridges package [ChatSession.inbox.unreadByConversation] into Riverpod and
/// seeds the inbox once after session bootstrap so the badge works before the
/// Messages tab is opened.
@Riverpod(keepAlive: true)
class HealthMessengerUnreadBadge extends _$HealthMessengerUnreadBadge {
  ChatSession? _boundSession;
  ValueListenable<Map<String, int>>? _unreadListenable;
  VoidCallback? _unreadListener;

  @override
  bool build() {
    ref.listen<HealthMessengerSessionState>(
      healthMessengerSessionProvider,
      (previous, next) => _syncToSession(next),
      fireImmediately: true,
    );
    ref.onDispose(_detach);
    return false;
  }

  void _syncToSession(HealthMessengerSessionState sessionState) {
    final session = sessionState.session;
    if (session == null || !sessionState.isReady) {
      _detach();
      if (ref.mounted) {
        state = false;
      }
      return;
    }

    if (identical(_boundSession, session)) {
      return;
    }

    _detachListenerOnly();
    _boundSession = session;

    try {
      final listenable = session.inbox.unreadByConversation;
      _unreadListenable = listenable;
      _unreadListener = () {
        if (!ref.mounted) {
          return;
        }
        state = _hasUnread(listenable.value);
      };
      listenable.addListener(_unreadListener!);
      state = _hasUnread(listenable.value);
    } on StateError {
      _boundSession = null;
      if (ref.mounted) {
        state = false;
      }
      return;
    }

    unawaited(_seedInbox(session));
  }

  Future<void> _seedInbox(ChatSession session) async {
    try {
      final auth = session.sessionAuth;
      final userId = session.currentUser?.id.trim();
      if (auth == null || userId == null || userId.isEmpty) {
        return;
      }

      final conversations = await session.client.getConversations(
        auth,
        forUserId: userId,
      );

      if (!ref.mounted || !identical(_boundSession, session)) {
        return;
      }

      session.inbox.seedFromConversations(conversations);
      if (ref.mounted) {
        state = _hasUnread(session.inbox.unreadByConversation.value);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[HealthMessengerUnreadBadge] seed failed: $error\n$stackTrace',
        );
      }
    }
  }

  static bool _hasUnread(Map<String, int> unreadMap) {
    return unreadMap.values.any((count) => count > 0);
  }

  void _detachListenerOnly() {
    final listenable = _unreadListenable;
    final listener = _unreadListener;
    if (listenable != null && listener != null) {
      listenable.removeListener(listener);
    }
    _unreadListenable = null;
    _unreadListener = null;
  }

  void _detach() {
    _detachListenerOnly();
    _boundSession = null;
  }
}
