import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/presentation/widgets/care_avatar.dart';
import 'package:vcare_admin/features/home/presentation/widgets/care_team_member_actions.dart';

class CareTeamMemberCard extends StatelessWidget {
  const CareTeamMemberCard({super.key, required this.member});

  final CareTeamMember member;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => context.pushNamed(
              AppRouter.careTeamDetailName,
              pathParameters: {'id': member.id},
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CareAvatar(member: member, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.roleLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            color: vcare.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: vcare.mutedForeground),
                ],
              ),
            ),
          ),
          CareTeamMemberActions(member: member),
        ],
      ),
    );
  }
}
