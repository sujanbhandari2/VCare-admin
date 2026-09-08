import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/features/feature_access/presentation/widgets/feature_access_gate.dart';

import 'live_chat_screen_content.dart';

/// Live Chat tab — real generic-chat integration via `health_messenger_ui`.
class LiveChatScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureAccessGate(
      isEnabled: (access) => access.healthChat,
      deniedTitle: 'Messages unavailable',
      deniedMessage: 'You do not have permission to manage messages.',
      deniedIcon: LucideIcons.messageSquare,
      child: LiveChatScreenContent(
        openNewChat: openNewChat,
        peerUserId: peerUserId,
      ),
    );
  }
}
