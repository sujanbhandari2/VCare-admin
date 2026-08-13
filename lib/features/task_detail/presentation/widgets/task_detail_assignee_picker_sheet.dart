import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/task_detail/presentation/providers/task_detail_assignees_state_provider.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

/// Team member picker for the task edit form. Tasks always need an assignee, so
/// there is no "Unassigned" option (web parity).
class TaskDetailAssigneePickerSheet extends ConsumerStatefulWidget {
  const TaskDetailAssigneePickerSheet({super.key, this.selectedId});

  final String? selectedId;

  static Future<AssociatedUser?> show(
    BuildContext context, {
    String? selectedId,
  }) {
    return context.showBottomSheet<AssociatedUser>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TaskDetailAssigneePickerSheet(selectedId: selectedId),
    );
  }

  @override
  ConsumerState<TaskDetailAssigneePickerSheet> createState() =>
      _TaskDetailAssigneePickerSheetState();
}

class _TaskDetailAssigneePickerSheetState
    extends ConsumerState<TaskDetailAssigneePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(taskDetailAssigneesStateProvider.notifier);
      if (ref.read(taskDetailAssigneesStateProvider).assignees.isEmpty) {
        notifier.fetchAssignees();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AssociatedUser> _filter(List<AssociatedUser> users) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users
        .where(
          (user) =>
              user.displayName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskDetailAssigneesStateProvider);
    final users = _filter(state.assignees);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final selectedId = widget.selectedId?.trim();

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Assign task',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search team members',
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: VCareRadius.lgAll),
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.fetching && state.assignees.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null && state.assignees.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: VcareInlineErrorCard(
                        message: state.error,
                        onRetry: () => ref
                            .read(taskDetailAssigneesStateProvider.notifier)
                            .fetchAssignees(forceRefresh: true),
                      ),
                    );
                  }

                  if (users.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: VcareEmptyStateCard(
                        icon: LucideIcons.users,
                        title: 'No team members found',
                        description: 'Try a different search.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 16),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _AssigneeTile(
                        user: user,
                        selected: selectedId == user.id,
                        onTap: () => context.pop(user),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneeTile extends StatelessWidget {
  const _AssigneeTile({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  final AssociatedUser user;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final subtitle = [
      if (user.role.trim().isNotEmpty) user.role,
      if (user.email.trim().isNotEmpty) user.email,
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: VCareRadius.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: vcare.primary.withValues(alpha: 0.12),
                child: Text(
                  _initials(user.displayName),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: vcare.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(LucideIcons.check, size: 16, color: vcare.primary),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
