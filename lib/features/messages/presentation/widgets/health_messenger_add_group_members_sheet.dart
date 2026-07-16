import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';

/// Multi-select sheet to add associated users to an existing group conversation.
class HealthMessengerAddGroupMembersSheet extends ConsumerStatefulWidget {
  const HealthMessengerAddGroupMembersSheet({
    super.key,
    required this.conversation,
  });

  final MessengerConversation conversation;

  static Future<void> show(
    BuildContext context, {
    required MessengerConversation conversation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HealthMessengerAddGroupMembersSheet(
        conversation: conversation,
      ),
    );
  }

  @override
  ConsumerState<HealthMessengerAddGroupMembersSheet> createState() =>
      _HealthMessengerAddGroupMembersSheetState();
}

class _HealthMessengerAddGroupMembersSheetState
    extends ConsumerState<HealthMessengerAddGroupMembersSheet> {
  final _queryController = TextEditingController();
  final _selectedIds = <String>{};
  bool _isSubmitting = false;

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

  List<MessengerUser> get _contacts {
    return ref.read(healthMessengerChatProvider.notifier).uiUsers;
  }

  List<MessengerUser> get _filtered {
    final notifier = ref.read(healthMessengerChatProvider.notifier);
    final query = _queryController.text.trim().toLowerCase();
    return _contacts.where((user) {
      if (notifier.isUserInGroup(widget.conversation.id, user)) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return user.username.toLowerCase().contains(query) ||
          user.roleLabel.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  List<MessengerUser> get _selectedUsers =>
      _contacts.where((user) => _selectedIds.contains(user.id)).toList();

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _submit() async {
    final selected = _selectedUsers;
    if (selected.isEmpty || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(healthMessengerChatProvider.notifier).addGroupMembers(
            widget.conversation,
            selected,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      // Notifier surfaces a toast; keep sheet open for retry.
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final chatState = ref.watch(healthMessengerChatProvider);
    final filtered = _filtered;
    final selected = _selectedUsers;
    final isLoading = chatState.isSuggestedUsersLoading;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final canSubmit = selected.isNotEmpty && !_isSubmitting;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: vcare.muted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Add people',
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
                if (selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: selected.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final user = selected[index];
                          final name = user.username.trim().isEmpty
                              ? user.id
                              : user.username.trim();
                          return InputChip(
                            label: Text(name),
                            onDeleted: () => _toggle(user.id),
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: TextField(
                    controller: _queryController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search people',
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
                      : filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No people available to add',
                            style: TextStyle(color: vcare.mutedForeground),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            final isSelected = _selectedIds.contains(user.id);
                            final displayName = user.username.trim().isEmpty
                                ? user.id
                                : user.username;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: isSelected
                                    ? vcare.muted.withValues(alpha: 0.6)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _toggle(user.id),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (user.roleLabel
                                                  .trim()
                                                  .isNotEmpty)
                                                Text(
                                                  user.roleLabel.trim(),
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
                                        Icon(
                                          isSelected
                                              ? LucideIcons.checkCircle
                                              : LucideIcons.circle,
                                          color: isSelected
                                              ? VCareColors.primary
                                              : vcare.mutedForeground,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: vcare.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${selected.length} selected',
                          style: TextStyle(
                            fontSize: 13,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: canSubmit ? _submit : null,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Add people'),
                      ),
                    ],
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
