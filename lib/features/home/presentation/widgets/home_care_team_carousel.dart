import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/presentation/widgets/care_team_member_card.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_constants.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_empty_state_card.dart';

/// parity: vcare-agent-app-2.0/src/features/home/components/HomeCareTeamCarousel.tsx
class HomeCareTeamCarousel extends StatelessWidget {
  const HomeCareTeamCarousel({
    super.key,
    required this.careTeam,
    this.onSeeAll,
    this.onAdd,
  });

  final List<CareTeamMember> careTeam;
  final VoidCallback? onSeeAll;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final showAddTile =
        careTeam.isNotEmpty && careTeam.length <= homeCareTeamCarouselLimit;
    final showHeaderAdd = careTeam.length > homeCareTeamCarouselLimit;
    final items = careTeam
        .take(showAddTile ? homeCareTeamCarouselLimit : homeCareTeamGridLimit)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Care Team',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (showHeaderAdd && onAdd != null) ...[
                GestureDetector(
                  onTap: onAdd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 14,
                        color: VCareColors.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: VCareColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (careTeam.isNotEmpty && onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: const Text(
                    'See all',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ),
        if (careTeam.isEmpty)
          HomeEmptyStateCard(
            icon: LucideIcons.users,
            title: 'Build your care team',
            description:
                'Add your advocate, doctors, insurance and employer contacts so help is one tap away.',
            ctaLabel: 'Add a contact',
            onTap: onAdd ?? onSeeAll,
            borderRadius: 24,
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                CareTeamMemberCard(member: items[i], compact: true),
              ],
              if (showAddTile) ...[
                const SizedBox(height: 12),
                _AddContactTile(onTap: onAdd ?? onSeeAll),
              ],
            ],
          ),
      ],
    );
  }
}

class _AddContactTile extends StatelessWidget {
  const _AddContactTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VCareColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            // Dotted border approximated with primary outline (web uses border-dotted).
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [VCareColors.primary.withValues(alpha: 0.04), vcare.card],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: VCareColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VCareColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: VCareColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Add contact',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VCareColors.foreground,
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
