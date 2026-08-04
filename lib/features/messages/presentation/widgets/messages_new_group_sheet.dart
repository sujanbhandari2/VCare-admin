import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_state_provider.dart';
import 'package:vcare_admin/features/care_team/presentation/widgets/care_avatar.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_utils.dart';
import 'package:vcare_admin/features/messages/presentation/providers/message_groups_provider.dart'
    hide isCareTeamOrgRole;
import 'package:vcare_admin/features/shell/data/shell_mock_data.dart';

class MessagesNewGroupSheet extends ConsumerStatefulWidget {
  const MessagesNewGroupSheet({super.key, required this.onCreated});

  final ValueChanged<MessageGroupItem> onCreated;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<MessageGroupItem> onCreated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MessagesNewGroupSheet(onCreated: onCreated),
    );
  }

  @override
  ConsumerState<MessagesNewGroupSheet> createState() =>
      _MessagesNewGroupSheetState();
}

class _MessagesNewGroupSheetState extends ConsumerState<MessagesNewGroupSheet> {
  final _nameController = TextEditingController();
  final _queryController = TextEditingController();
  final _selectedIds = <String>{};

  List<CareTeamMember> get _contacts => ref
      .watch(careTeamStateProvider)
      .members
      .where((member) => !isCareTeamOrgRole(member.role))
      .toList();

  @override
  void dispose() {
    _nameController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  List<CareTeamMember> get _filtered {
    final query = _queryController.text.trim().toLowerCase();
    if (query.isEmpty) return _contacts;
    return _contacts.where((member) {
      return member.name.toLowerCase().contains(query) ||
          member.roleLabel.toLowerCase().contains(query);
    }).toList();
  }

  List<CareTeamMember> get _selectedMembers =>
      _contacts.where((member) => _selectedIds.contains(member.id)).toList();

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _create() {
    final members = _selectedMembers;
    if (members.length < 2) return;

    final name = _nameController.text.trim().isEmpty
        ? _defaultGroupName(members)
        : _nameController.text.trim();

    final created = ref
        .read(messageGroupsProvider.notifier)
        .create(name: name, members: members);
    widget.onCreated(created);
    Navigator.of(context).pop();
  }

  String _defaultGroupName(List<CareTeamMember> members) {
    final names = members
        .take(3)
        .map((member) => member.name.split(' ').first)
        .join(', ');
    if (members.length > 3) {
      return '$names +${members.length - 3}';
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final filtered = _filtered;
    final selected = _selectedMembers;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Icon(LucideIcons.users, color: VCareColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'New group',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final member in selected)
                          _SelectedChip(
                            member: member,
                            onRemove: () => _toggle(member.id),
                          ),
                      ],
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
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No people match your search',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: vcare.mutedForeground),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final member = filtered[index];
                            final checked = _selectedIds.contains(member.id);
                            return ListTile(
                              onTap: () => _toggle(member.id),
                              leading: CareAvatar(member: member, size: 40),
                              title: Text(
                                member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                member.roleLabel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                  color: vcare.mutedForeground,
                                ),
                              ),
                              trailing: Icon(
                                checked
                                    ? LucideIcons.checkCircle
                                    : LucideIcons.circle,
                                color: checked
                                    ? VCareColors.primary
                                    : vcare.mutedForeground,
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: vcare.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${selected.length} selected',
                          style: TextStyle(
                            fontSize: 12,
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
                        onPressed: selected.length < 2 ? null : _create,
                        child: const Text('Create group'),
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

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({required this.member, required this.onRemove});

  final CareTeamMember member;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 8, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: vcare.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CareAvatar(member: member, size: 20),
          const SizedBox(width: 6),
          Text(
            member.name.split(' ').first,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(LucideIcons.x, size: 14, color: vcare.mutedForeground),
          ),
        ],
      ),
    );
  }
}
