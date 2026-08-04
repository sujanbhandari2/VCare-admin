import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_state_provider.dart';
import 'package:vcare_admin/features/care_team/presentation/widgets/care_avatar.dart';
import 'package:vcare_admin/features/care_team/presentation/widgets/care_team_member_actions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class CareTeamMemberCard extends ConsumerWidget {
  const CareTeamMemberCard({
    super.key,
    required this.member,
    this.showManage = false,
    this.compact = false,
  });

  final CareTeamMember member;

  /// My team list — show Edit/Delete menu.
  final bool showManage;

  /// Home carousel compact layout uses inline actions without footer bar.
  final bool compact;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove contact?'),
        content: Text(
          '${member.name} will be removed from your care team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: VCareColors.destructive),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    var success = false;
    await ref.read(careTeamStateProvider.notifier).deleteContact(
          member.id,
          onCompleted: (ok) => success = ok,
        );

    if (!context.mounted) return;
    if (success) {
      context.showVcareToast(
        title: 'Removed',
        variant: VcareToastVariant.success,
      );
    } else {
      final error = ref.read(careTeamStateProvider).deleteError;
      context.showVcareToast(
        title: 'Could not remove contact',
        description: error ?? 'Something went wrong. Please try again.',
        variant: VcareToastVariant.destructive,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vcare = context.vcare;
    final deleting = ref.watch(careTeamStateProvider).deleting;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CareAvatar(member: member, size: compact ? 48 : 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.cardRoleLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.accent,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                CareTeamMemberActions(
                  member: member,
                  variant: CareTeamMemberActionsVariant.inline,
                  isDeleting: deleting,
                  onDelete: showManage
                      ? () => _confirmDelete(context, ref)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
