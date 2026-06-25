import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/features/home/utils/home_stats_utils.dart';

class CommissionSummarySection extends StatelessWidget {
  const CommissionSummarySection({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.isAgencyGroup,
    this.error,
    this.onRetry,
  });

  final CommissionSummary? summary;
  final bool isLoading;
  final bool isAgencyGroup;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _SummaryError(message: error!, onRetry: onRetry);
    }

    final totalSales = isLoading
        ? '—'
        : formatAgentStatMoney(summary?.totalSales);
    final totalCommission = isLoading
        ? '—'
        : isAgencyGroup
            ? 'XXX'
            : formatAgentStatMoney(summary?.totalCommission);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Sales',
                value: totalSales,
                delta: 'This month',
                icon: LucideIcons.wallet,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VCareColors.muted.withValues(alpha: 0.9),
                    VCareColors.muted.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Commission Earned',
                value: totalCommission,
                delta: isAgencyGroup ? 'Paid to agency' : 'This month',
                deltaPositive: isAgencyGroup ? null : true,
                icon: LucideIcons.dollarSign,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VCareColors.success.withValues(alpha: 0.15),
                    VCareColors.success.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (isAgencyGroup) ...[
          const SizedBox(height: 12),
          const _AgencyInfoBanner(),
        ],
      ],
    );
  }
}

class _AgencyInfoBanner extends StatelessWidget {
  const _AgencyInfoBanner();

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 16, color: vcare.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Commissions are paid to your agency and distributed according to your agency's policy.",
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: vcare.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  const _SummaryError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.gradient,
    this.deltaPositive,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Gradient gradient;
  final bool? deltaPositive;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final deltaColor = deltaPositive == null
        ? vcare.mutedForeground
        : deltaPositive!
            ? VCareColors.success
            : VCareColors.destructive;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: vcare.card.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16),
                ),
                if (deltaPositive != null)
                  Icon(
                    deltaPositive! ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 16,
                    color: deltaColor,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              delta,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: deltaColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
