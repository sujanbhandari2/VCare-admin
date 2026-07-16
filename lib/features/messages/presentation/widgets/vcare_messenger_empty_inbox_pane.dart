import 'package:flutter/material.dart';

import 'package:vcare_admin/features/messages/presentation/widgets/messages_empty_state.dart';

/// Host empty-inbox pane for [MessengerChatShell.emptyInboxBuilder].
///
/// Mirrors the package example's scroll + pull-to-refresh pattern while
/// reusing the project's [MessagesEmptyState] UI.
class VcareMessengerEmptyInboxPane extends StatelessWidget {
  const VcareMessengerEmptyInboxPane({
    super.key,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  final Future<void> Function() onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Opacity(
                opacity: isRefreshing ? 0.7 : 1,
                child: const MessagesEmptyState(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
