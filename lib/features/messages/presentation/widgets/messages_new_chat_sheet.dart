import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/care_team/presentation/widgets/care_avatar.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_state_provider.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_utils.dart';
import 'package:vcare_admin/features/shell/data/shell_mock_data.dart';

class MessagesNewChatSheet extends ConsumerStatefulWidget {
  const MessagesNewChatSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MessagesNewChatSheet(),
    );
  }

  @override
  ConsumerState<MessagesNewChatSheet> createState() =>
      _MessagesNewChatSheetState();
}

class _MessagesNewChatSheetState extends ConsumerState<MessagesNewChatSheet> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  bool _matches(CareTeamMember member, String query) {
    if (query.isEmpty) return true;
    return member.name.toLowerCase().contains(query) ||
        (member.email ?? '').toLowerCase().contains(query);
  }

  void _openChat(String memberId) {
    Navigator.of(context).pop();
    context.pushNamed(
      AppRouter.careTeamDetailName,
      pathParameters: {'id': memberId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final careTeam = ref.watch(careTeamStateProvider).members;
    final query = _queryController.text.trim().toLowerCase();
    final suggested = careTeam
        .where((member) => !isCareTeamOrgRole(member.role))
        .where((member) => _matches(member, query))
        .toList();
    final organizations = careTeam
        .where((member) => isCareTeamOrgRole(member.role))
        .where((member) => _matches(member, query))
        .toList();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Align(
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    if (suggested.isNotEmpty) ...[
                      _SectionLabel('Suggested', vcare: vcare),
                      const SizedBox(height: 8),
                      for (final member in suggested)
                        _ChatPickRow(
                          member: member,
                          online: ShellMockData.messageThreads(careTeam: careTeam).any(
                            (thread) =>
                                thread.contact.id == member.id &&
                                thread.isOnline,
                          ),
                          onTap: () => _openChat(member.id),
                        ),
                      const SizedBox(height: 16),
                    ],
                    if (organizations.isNotEmpty) ...[
                      _SectionLabel('Organizations', vcare: vcare),
                      const SizedBox(height: 8),
                      for (final member in organizations)
                        _ChatPickRow(
                          member: member,
                          onTap: () => _openChat(member.id),
                        ),
                    ],
                    if (suggested.isEmpty && organizations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No people match your search',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: vcare.mutedForeground),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.vcare});

  final String label;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: vcare.mutedForeground,
      ),
    );
  }
}

class _ChatPickRow extends StatelessWidget {
  const _ChatPickRow({
    required this.member,
    required this.onTap,
    this.online = false,
  });

  final CareTeamMember member;
  final VoidCallback onTap;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CareAvatar(member: member, size: 44),
                    if (!isCareTeamOrgRole(member.role))
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: online
                                ? const Color(0xFF22C55E)
                                : vcare.mutedForeground.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (member.email != null)
                        Text(
                          member.email!,
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
