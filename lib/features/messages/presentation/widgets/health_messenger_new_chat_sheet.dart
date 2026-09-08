import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/features/messages/health_messenger/mappers/associated_user_messenger_mapper.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_role_badge.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';

class HealthMessengerNewChatSheet extends ConsumerStatefulWidget {
  const HealthMessengerNewChatSheet({
    super.key,
    required this.onOpenDirectChat,
  });

  /// Shell-provided open handler (creates/selects + pushes mobile thread).
  final Future<void> Function(MessengerUser user) onOpenDirectChat;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(MessengerUser user) onOpenDirectChat,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      builder: (context) => HealthMessengerNewChatSheet(
        onOpenDirectChat: onOpenDirectChat,
      ),
    );
  }

  @override
  ConsumerState<HealthMessengerNewChatSheet> createState() =>
      _HealthMessengerNewChatSheetState();
}

class _HealthMessengerNewChatSheetState
    extends ConsumerState<HealthMessengerNewChatSheet> {
  final _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthMessengerChatProvider.notifier).ensureAssociatedUsersLoaded();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  bool _matches(AssociatedUser user, String query) {
    if (query.isEmpty) {
      return true;
    }
    return user.displayName.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query) ||
        AssociatedUserMessengerMapper.displayRoleFor(user)
            .toLowerCase()
            .contains(query);
  }

  Future<void> _openChat(MessengerUser user) async {
    final openDirectChat = widget.onOpenDirectChat;
    Navigator.of(context).pop();
    // Use the shell callback so mobile also pushes the conversation route.
    await openDirectChat(user);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final chatState = ref.watch(healthMessengerChatProvider);
    final query = _queryController.text.trim().toLowerCase();
    final people = chatState.associatedUsers
        .where((user) => _matches(user, query))
        .map(AssociatedUserMessengerMapper.toMessengerUser)
        .toList(growable: false);
    final isLoading =
        chatState.isBootstrapping || chatState.isSuggestedUsersLoading;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Icon(LucideIcons.userPlus, color: VCareColors.primary),
              const SizedBox(width: 8),
              const Text(
                'New chat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _queryController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search people by name or role',
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: vcare.mutedForeground,
                    ),
                    filled: true,
                    fillColor: vcare.muted.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: vcare.border),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : people.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No people match your search',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: vcare.mutedForeground),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: people.length,
                            itemBuilder: (context, index) {
                              final user = people[index];
                              return _ChatPickRow(
                                user: user,
                                onTap: () => _openChat(user),
                              );
                            },
                          ),
              ),
      ],
    );
  }
}

class _ChatPickRow extends StatelessWidget {
  const _ChatPickRow({required this.user, required this.onTap});

  final MessengerUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final displayName = user.username.trim().isEmpty ? user.id : user.username;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: vcare.muted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                VcareMessengerAvatar(
                  displayTitle: displayName,
                  imageUrl: user.avatarUrl,
                  size: 44,
                  borderRadius: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.roleLabel.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            VcareMessengerRoleBadge(
                              roleLabel: user.roleLabel,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                      if (user.email.trim().isNotEmpty)
                        Text(
                          user.email.trim(),
                          style: TextStyle(
                            fontSize: 12,
                            color: vcare.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VCareColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
