import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

class CommissionEmptyState extends StatelessWidget {
  const CommissionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

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
                VCareColors.primary.withValues(alpha: 0.1),
                vcare.card,
                VCareColors.success.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: vcare.border),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: VCareColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      size: 28,
                      color: VCareColors.primary,
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 14,
                        color: VCareColors.success,
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
                'Your commissions and sales will appear here once your first client signs up.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: vcare.mutedForeground,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.goNamed(AppRouter.clientsName),
                icon: const Icon(LucideIcons.arrowRight, size: 16),
                label: const Text('View clients'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(
              child: _TipCard(
                icon: LucideIcons.users,
                title: 'Invite clients',
                description: 'Share your referral link to start earning.',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _TipCard(
                icon: LucideIcons.sparkles,
                title: 'Track in real time',
                description: 'Every signed agreement appears here.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: vcare.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: vcare.border),
          ),
          child: InkWell(
            onTap: () => context.pushNamed(AppRouter.idCardName),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: VCareColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.share2,
                      size: 16,
                      color: VCareColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share your referral link',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Grow your book of business',
                          style: TextStyle(
                            fontSize: 12,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 16,
                    color: vcare.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: vcare.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16),
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
