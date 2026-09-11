import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_role_badge.dart';

class HealthMessengerNewGroupSheet extends ConsumerStatefulWidget {
  const HealthMessengerNewGroupSheet({
    super.key,
    this.onCreateGroupRequested,
  });

  /// Shell-provided create handler (creates group + pushes mobile thread).
  final Future<void> Function(MessengerGroupCreateRequest request)?
      onCreateGroupRequested;

  static Future<void> show(
    BuildContext context, {
    Future<void> Function(MessengerGroupCreateRequest request)?
        onCreateGroupRequested,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      builder: (context) => HealthMessengerNewGroupSheet(
        onCreateGroupRequested: onCreateGroupRequested,
      ),
    );
  }

  @override
  ConsumerState<HealthMessengerNewGroupSheet> createState() =>
      _HealthMessengerNewGroupSheetState();
}

class _HealthMessengerNewGroupSheetState
    extends ConsumerState<HealthMessengerNewGroupSheet> {
  final _nameController = TextEditingController();
  final _queryController = TextEditingController();
  final _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthMessengerChatProvider.notifier).ensureAssociatedUsersLoaded();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  List<MessengerUser> get _contacts {
    return ref.read(healthMessengerChatProvider.notifier).uiUsers;
  }

  List<MessengerUser> get _filtered {
    final query = _queryController.text.trim().toLowerCase();
    if (query.isEmpty) return _contacts;
    return _contacts.where((user) {
      return user.username.toLowerCase().contains(query) ||
          user.roleLabel.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
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

  String _defaultGroupName(List<MessengerUser> users) {
    final names = users
        .take(3)
        .map((user) => user.username.split(' ').first)
        .where((part) => part.isNotEmpty)
        .join(', ');
    if (users.length > 3) {
      return '$names +${users.length - 3}';
    }
    return names.isEmpty ? 'Group' : names;
  }

  Future<void> _create() async {
    final selected = _selectedUsers;
    if (selected.length < 2) return;

    final name = _nameController.text.trim().isEmpty
        ? _defaultGroupName(selected)
        : _nameController.text.trim();

    final request = MessengerGroupCreateRequest(
      selectedUsers: selected,
      groupName: name,
    );
    final createGroup = widget.onCreateGroupRequested;
    Navigator.of(context).pop();
    if (createGroup != null) {
      // Use the shell callback so mobile also pushes the conversation route.
      await createGroup(request);
      return;
    }
    await ref
        .read(healthMessengerChatProvider.notifier)
        .createGroupChatFromRequest(request);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final chatState = ref.watch(healthMessengerChatProvider);
    final filtered = _filtered;
    final selected = _selectedUsers;
    final isLoading = chatState.isSuggestedUsersLoading;
    final canCreate = selected.length >= 2;

    return Column(
      children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'New group',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Group name (optional)',
                      filled: true,
                      fillColor: vcare.muted.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: vcare.border),
                      ),
                    ),
                  ),
                ),
                if (selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: selected.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final user = selected[index];
                          return _SelectedChip(
                            user: user,
                            onRemove: () => _toggle(user.id),
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                            'No people match your search',
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
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      displayName,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (user.roleLabel
                                                      .trim()
                                                      .isNotEmpty) ...[
                                                    const SizedBox(width: 6),
                                                    VcareMessengerRoleBadge(
                                                      roleLabel:
                                                          user.roleLabel,
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
                                                    color:
                                                        vcare.mutedForeground,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 26,
                                          height: 26,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? VCareColors.primary
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? VCareColors.primary
                                                  : vcare.border,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  LucideIcons.check,
                                                  size: 15,
                                                  color: Colors.white,
                                                )
                                              : null,
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
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: canCreate ? _create : null,
                        child: const Text('Create group'),
                      ),
                    ],
                  ),
                ),
      ],
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({required this.user, required this.onRemove});

  final MessengerUser user;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final displayName =
        user.username.trim().isEmpty ? user.id : user.username.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: vcare.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayName, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              LucideIcons.x,
              size: 14,
              color: vcare.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
