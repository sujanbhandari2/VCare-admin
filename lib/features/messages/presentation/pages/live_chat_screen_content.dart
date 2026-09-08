import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_mobile_direct_chat_provider.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_provider.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_chat_body.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_scaffold.dart';

/// Live Chat body — only mounted when health chat is enabled.
class LiveChatScreenContent extends ConsumerStatefulWidget {
  const LiveChatScreenContent({
    super.key,
    this.openNewChat = false,
    this.peerUserId,
  });

  /// When true (e.g. `/messages?newChat=1`), opens the New chat user picker.
  final bool openNewChat;

  /// When set (e.g. `/messages?userId=`), opens/starts a DM with that peer.
  final String? peerUserId;

  @override
  ConsumerState<LiveChatScreenContent> createState() =>
      _LiveChatScreenContentState();
}

class _LiveChatScreenContentState extends ConsumerState<LiveChatScreenContent> {
  final _searchController = TextEditingController();
  final _startNewChatController = MessengerStartNewChatController();
  var _handledOpenNewChat = false;
  var _handledPeerUserId = false;

  @override
  void initState() {
    super.initState();
    _scheduleOpenNewChatIfNeeded();
    _scheduleOpenPeerChatIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LiveChatScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openNewChat && !oldWidget.openNewChat) {
      _handledOpenNewChat = false;
      _scheduleOpenNewChatIfNeeded();
    }
    if (widget.peerUserId != oldWidget.peerUserId) {
      _handledPeerUserId = false;
      _scheduleOpenPeerChatIfNeeded();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _waitForMessengerShellReady() async {
    for (var attempt = 0; attempt < 60; attempt++) {
      if (!mounted) {
        return;
      }
      final session = ref.read(healthMessengerSessionProvider).session;
      final chatState = ref.read(healthMessengerChatProvider);
      if (session?.sessionAuth != null &&
          !chatState.showPreSessionConnectingShimmer &&
          _startNewChatController.isAttached) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _primeMobileDirectChatHandlerIfNeeded() async {
    final mobile = ref.read(healthMessengerMobileDirectChatProvider.notifier);
    if (mobile.hasShellHandler) {
      return;
    }
    await _startNewChatController.openDirectChatPicker(context);
    if (!mounted) {
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _clearDeepLinkQuery(String parameterName) {
    if (GoRouterState.of(context).uri.queryParameters[parameterName] == null) {
      return;
    }
    context.goNamed(AppRouter.messages.toPathName);
  }

  void _scheduleOpenNewChatIfNeeded() {
    if (!widget.openNewChat || _handledOpenNewChat) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _handledOpenNewChat || !widget.openNewChat) return;
      _handledOpenNewChat = true;
      await _waitForMessengerShellReady();
      if (!mounted) {
        return;
      }
      await _startNewChatController.openDirectChatPicker(context);
      if (!mounted) {
        return;
      }
      _clearDeepLinkQuery('newChat');
    });
  }

  void _scheduleOpenPeerChatIfNeeded() {
    final peerId = widget.peerUserId?.trim();
    if (peerId == null || peerId.isEmpty || _handledPeerUserId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _handledPeerUserId) return;
      _handledPeerUserId = true;
      await _waitForMessengerShellReady();
      if (!mounted) {
        return;
      }
      await _primeMobileDirectChatHandlerIfNeeded();
      if (!mounted) {
        return;
      }
      await ref.read(healthMessengerMobileDirectChatProvider.notifier).openDirectChat(
            ref
                .read(healthMessengerChatProvider.notifier)
                .messengerUserForPlatformId(peerId),
          );
      if (!mounted) {
        return;
      }
      _clearDeepLinkQuery('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return VcareStickyTabScaffold(
      header: VcarePageHeader(
        title: 'Messages',
        subtitle: 'Chat with your care team',
      ),
      search: VcareStickySearchField(
        controller: _searchController,
        hintText: 'Search messages, people or groups',
        onChanged: (_) => setState(() {}),
      ),
      body: HealthMessengerChatBody(
        conversationSearchController: _searchController,
        startNewChatController: _startNewChatController,
      ),
    );
  }
}
