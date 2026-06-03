import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/home/data/home_mock_data.dart';
import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/home/presentation/widgets/care_avatar.dart';
import 'package:flutter_template/shared/widgets/vcare_page_header.dart';

class CareTeamScreen extends StatelessWidget {
  const CareTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: VcarePageHeader(
              title: 'Care Team',
              subtitle: 'Your people, one tap away.',
              showBack: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.pushNamed(AppRouter.careTeamNewName),
                      icon: const Icon(LucideIcons.userPlus, size: 18),
                      label: const Text('Add contact'),
                    ),
                  );
                }
                final member = HomeMockData.careTeam[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CareTeamCard(member: member),
                );
              }, childCount: HomeMockData.careTeam.length + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareTeamCard extends StatelessWidget {
  const _CareTeamCard({required this.member});

  final CareTeamMember member;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.pushNamed(
          AppRouter.careTeamDetailName,
          pathParameters: {'id': member.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: vcare.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
