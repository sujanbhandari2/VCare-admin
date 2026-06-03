import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/home/presentation/widgets/care_avatar.dart';
import 'package:flutter_template/features/home/presentation/widgets/home_empty_state_card.dart';
import 'package:flutter_template/features/home/presentation/widgets/home_horizontal_carousel.dart';
import 'package:flutter_template/features/home/presentation/widgets/home_section_header.dart';

class HomeCareTeamCarousel extends StatelessWidget {
  const HomeCareTeamCarousel({
    super.key,
    required this.careTeam,
    this.previewEmpty = false,
    this.onPreviewToggle,
    this.onSeeAll,
    this.onMemberTap,
  });

  final List<CareTeamMember> careTeam;
  final bool previewEmpty;
  final VoidCallback? onPreviewToggle;
  final VoidCallback? onSeeAll;
  final void Function(CareTeamMember member)? onMemberTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final team = previewEmpty ? <CareTeamMember>[] : careTeam.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Your Care Team',
          seeAllLabel: team.isNotEmpty ? 'See all' : null,
          onSeeAll: onSeeAll,
          showPreviewToggle: kDebugMode,
          previewEmpty: previewEmpty,
          onPreviewToggle: onPreviewToggle,
        ),
        if (team.isEmpty)
          HomeEmptyStateCard(
            icon: LucideIcons.users,
            title: 'Build your care team',
            description:
                'Add your advocate, doctors, insurance and employer contacts so help is one tap away.',
            ctaLabel: 'Add a contact',
            onTap: onSeeAll,
            borderRadius: 24,
          )
        else
          HomeHorizontalCarouselSized(
            height: 88,
            itemCount: team.length,
            itemWidth: 280,
            itemBuilder: (context, index) {
              final c = team[index];
              return _CareTeamCard(
                member: c,
                vcare: vcare,
                onTap: () => onMemberTap?.call(c),
              );
            },
          ),
      ],
    );
  }
}

class _CareTeamCard extends StatelessWidget {
  const _CareTeamCard({required this.member, required this.vcare, this.onTap});

  final CareTeamMember member;
  final VCareThemeExtension vcare;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final actionIcon = member.isOrg
        ? LucideIcons.phone
        : LucideIcons.messageCircle;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CareAvatar(member: member, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (member.role == CareTeamRole.advocate
                              ? 'Your Advocate'
                              : member.roleLabel)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: vcare.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VCareColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(actionIcon, size: 20, color: VCareColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
