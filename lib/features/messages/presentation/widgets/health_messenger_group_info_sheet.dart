import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Group info: rename, member list, and remove members.
class HealthMessengerGroupInfoSheet extends ConsumerStatefulWidget {
  const HealthMessengerGroupInfoSheet({
    super.key,
    required this.conversation,
  });

  final MessengerConversation conversation;

  static Future<void> show(
    BuildContext context, {
    required MessengerConversation conversation,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => HealthMessengerGroupInfoSheet(
        conversation: conversation,
      ),
    );
  }

  @override
  ConsumerState<HealthMessengerGroupInfoSheet> createState() =>
      _HealthMessengerGroupInfoSheetState();
}

class _HealthMessengerGroupInfoSheetState
    extends ConsumerState<HealthMessengerGroupInfoSheet> {
  late final TextEditingController _nameController;
  List<ConversationParticipant>? _members;
  Object? _loadError;
  bool _isLoading = true;
  bool _isRenaming = false;
  String? _removingUserId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.conversation.title.trim(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadMembers());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final members = await ref
          .read(healthMessengerChatProvider.notifier)
          .listGroupMembers(widget.conversation.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _rename() async {
    final next = _nameController.text.trim();
    final current = widget.conversation.title.trim();
    if (next.isEmpty || next == current || _isRenaming) {
      return;
    }
    setState(() => _isRenaming = true);
    try {
      await ref.read(healthMessengerChatProvider.notifier).renameGroupConversation(
            widget.conversation,
            next,
          );
    } catch (_) {
      // Notifier toast.
    } finally {
      if (mounted) {
        setState(() => _isRenaming = false);
      }
    }
  }

  Future<void> _removeMember(ConversationParticipant participant) async {
    final userId = participant.user.id.trim().isNotEmpty
        ? participant.user.id.trim()
        : participant.userId.trim();
    if (userId.isEmpty || _removingUserId != null) {
      return;
    }

    final displayName = participant.user.username.trim().isEmpty
        ? userId
        : participant.user.username.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove $displayName from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.vcare.destructive,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _removingUserId = userId);
    try {
      await ref.read(healthMessengerChatProvider.notifier).removeGroupMember(
            conversationId: widget.conversation.id,
            userId: userId,
          );
      await _loadMembers();
    } catch (_) {
      // Notifier toast.
    } finally {
      if (mounted) {
        setState(() => _removingUserId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final chatState = ref.watch(healthMessengerChatProvider);
    final currentUserId = chatState.currentUser?.id.trim() ?? '';
    final members = _members ?? const <ConversationParticipant>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Group info',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(LucideIcons.x, color: vcare.mutedForeground),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Group name',
                    filled: true,
                    fillColor: vcare.muted.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: vcare.border),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => unawaited(_rename()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isRenaming ? null : () => unawaited(_rename()),
                child: _isRenaming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Members (${members.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: vcare.mutedForeground,
              ),
            ),
          ),
        ),
        Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _loadError != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Could not load members',
                                style: TextStyle(color: vcare.mutedForeground),
                              ),
                              TextButton(
                                onPressed: () => unawaited(_loadMembers()),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : members.isEmpty
                      ? Center(
                          child: Text(
                            'No members found',
                            style: TextStyle(color: vcare.mutedForeground),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final participant = members[index];
                            final userId = participant.user.id.trim().isNotEmpty
                                ? participant.user.id.trim()
                                : participant.userId.trim();
                            final isSelf = userId == currentUserId;
                            final displayName =
                                participant.user.username.trim().isEmpty
                                ? userId
                                : participant.user.username.trim();
                            final roleLabel = participant.user.role.label;
                            final isRemoving = _removingUserId == userId;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      VcareMessengerAvatar(
                                        displayTitle: displayName,
                                        imageUrl: participant.user.avatarUrl,
                                        size: 44,
                                        borderRadius: 16,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isSelf
                                                  ? '$displayName (you)'
                                                  : displayName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (roleLabel.trim().isNotEmpty)
                                              Text(
                                                roleLabel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: vcare.mutedForeground,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!isSelf)
                                        IconButton(
                                          onPressed: isRemoving
                                              ? null
                                              : () => unawaited(
                                                    _removeMember(participant),
                                                  ),
                                          icon: isRemoving
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Icon(
                                                  LucideIcons.userMinus,
                                                  color: context.vcare.destructive,
                                                ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
