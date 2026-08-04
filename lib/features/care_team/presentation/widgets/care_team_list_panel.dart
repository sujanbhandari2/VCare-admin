import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/presentation/widgets/care_team_member_card.dart';

class CareTeamListPanel extends StatelessWidget {
  const CareTeamListPanel({
    super.key,
    required this.team,
    this.title,
    this.emptyMessage,
    this.showManage = false,
  });

  final List<CareTeamMember> team;
  final String? title;
  final String? emptyMessage;
  final bool showManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
        ],
        if (team.isEmpty)
          emptyMessage != null
              ? Text(
                  emptyMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.vcare.mutedForeground,
                  ),
                )
              : const SizedBox.shrink()
        else
          for (var i = 0; i < team.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            CareTeamMemberCard(member: team[i], showManage: showManage),
          ],
      ],
    );
  }
}
