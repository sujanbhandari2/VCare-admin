import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_chat_body.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_new_chat_sheet.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/messages_header_new_menu.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_scaffold.dart';

/// Live Chat tab — real generic-chat integration via `health_messenger_ui`.
class LiveChatScreen extends ConsumerStatefulWidget {
  const LiveChatScreen({
    super.key,
    this.openNewChat = false,
    this.peerUserId,
  });

  /// When true (e.g. `/messages?newChat=1`), opens the New chat user picker.
  final bool openNewChat;

  /// When set (e.g. `/messages?userId=`), opens/starts a DM with that peer.
  final String? peerUserId;

  @override
  ConsumerState<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends ConsumerState<LiveChatScreen> {
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
  void didUpdateWidget(covariant LiveChatScreen oldWidget) {
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

  void _scheduleOpenNewChatIfNeeded() {
    if (!widget.openNewChat || _handledOpenNewChat) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _handledOpenNewChat || !widget.openNewChat) return;
      _handledOpenNewChat = true;
      // Open directly so we do not depend on the messenger shell having
      // attached [MessengerStartNewChatController] yet on first paint.
      HealthMessengerNewChatSheet.show(context);
      // Drop the query immediately so dismiss/open-chat does not race a later
      // goNamed, and so tab revisits do not reopen the sheet.
      if (GoRouterState.of(context).uri.queryParameters['newChat'] == '1') {
        context.goNamed(AppRouter.messages.toPathName);
      }
    });
  }

  void _scheduleOpenPeerChatIfNeeded() {
    final peerId = widget.peerUserId?.trim();
    if (peerId == null || peerId.isEmpty || _handledPeerUserId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _handledPeerUserId) return;
      _handledPeerUserId = true;
      await ref.read(healthMessengerChatProvider.notifier).openDirectChat(
            MessengerUser(
              id: peerId,
              username: 'Care team contact',
            ),
          );
      if (!mounted) return;
      if (GoRouterState.of(context).uri.queryParameters['userId'] != null) {
        context.goNamed(AppRouter.messages.toPathName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return VcareStickyTabScaffold(
      header: VcarePageHeader(
        title: 'Messages',
        subtitle: 'Chat with your care team',
        action: MessagesHeaderNewMenu(
          vcare: vcare,
          onNewChat: () =>
              _startNewChatController.openDirectChatPicker(context),
          onNewGroup: () =>
              _startNewChatController.openGroupChatPicker(context),
        ),
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
