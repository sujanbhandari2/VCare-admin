import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_chat_body.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/messages_header_new_menu.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_scaffold.dart';

/// Live Chat tab — real generic-chat integration via `health_messenger_ui`.
class LiveChatScreen extends ConsumerStatefulWidget {
  const LiveChatScreen({super.key});

  @override
  ConsumerState<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends ConsumerState<LiveChatScreen> {
  final _searchController = TextEditingController();
  final _startNewChatController = MessengerStartNewChatController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
