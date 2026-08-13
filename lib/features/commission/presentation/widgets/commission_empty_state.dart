import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/presentation/widgets/referral_share_sheet.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';

class CommissionEmptyState extends ConsumerWidget {
  const CommissionEmptyState({super.key, this.isAgencyTied = false});

  final bool isAgencyTied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vcare = context.vcare;
    final profile = ref.watch(localProfileStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                vcare.primary.withValues(alpha: 0.1),
                vcare.card,
                vcare.success.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: VCareRadius.xxlAll,
            border: Border.all(color: vcare.border),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: vcare.primary.withValues(alpha: 0.1),
                  borderRadius: VCareRadius.xlAll,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      size: 28,
                      color: vcare.primary,
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 14,
                        color: vcare.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No sales yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                isAgencyTied
                    ? 'Your sales will appear here when your first client has been successfully processed.'
                    : 'Your commissions and sales will appear here when your first client has been successfully processed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: vcare.mutedForeground,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.goNamed(AppRouter.clientsName),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View clients'),
                    SizedBox(width: 6),
                    Icon(LucideIcons.arrowRight, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InviteTipCard(
                onTap: () => showReferralShareSheet(context, profile: profile),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: _TipCard(
                icon: LucideIcons.sparkles,
                title: 'Track in real time',
                description:
                    'Every signed agreement appears here automatically.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InviteTipCard extends StatelessWidget {
  const _InviteTipCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.xlAll,
        side: BorderSide(color: vcare.primary.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.xlAll,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: vcare.primary.withValues(alpha: 0.15),
                  borderRadius: VCareRadius.mdAll,
                ),
                child: Icon(LucideIcons.users, size: 16, color: vcare.primary),
              ),
              const SizedBox(height: 10),
              const Text(
                'Invite clients',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Share your referral link to start earning.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: vcare.mutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(LucideIcons.share2, size: 14, color: vcare.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Share link',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: vcare.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.arrowRight, size: 14, color: vcare.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.3),
        borderRadius: VCareRadius.xlAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: vcare.card,
              borderRadius: VCareRadius.mdAll,
              border: Border.all(color: vcare.border.withValues(alpha: 0.6)),
            ),
            child: Icon(icon, size: 16, color: vcare.mutedForeground),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: vcare.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
