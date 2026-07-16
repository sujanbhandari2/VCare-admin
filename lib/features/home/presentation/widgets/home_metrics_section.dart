import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Overview stat cards — parity with vcareapp [HomeMetricsSection].
class HomeMetricsSection extends StatelessWidget {
  const HomeMetricsSection({
    super.key,
    required this.hasCommission,
    required this.totalClients,
    required this.totalCommission,
    required this.totalSales,
    this.onTotalClientsTap,
    this.onTotalCommissionTap,
    this.onTotalSalesTap,
  });

  final bool hasCommission;
  final String totalClients;
  final String totalCommission;
  final String totalSales;
  final VoidCallback? onTotalClientsTap;
  final VoidCallback? onTotalCommissionTap;
  final VoidCallback? onTotalSalesTap;

  @override
  Widget build(BuildContext context) {
    final secondaryLabel =
        hasCommission ? 'Total Commission' : 'Total Sales';
    final secondaryValue = hasCommission ? totalCommission : totalSales;
    final secondaryOnTap =
        hasCommission ? onTotalCommissionTap : onTotalSalesTap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Clients',
                value: totalClients,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x26F59E0B), Color(0x0DF59E0B)],
                ),
                onTap: onTotalClientsTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: secondaryLabel,
                value: secondaryValue,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VCareColors.primary.withValues(alpha: 0.15),
                    VCareColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                onTap: secondaryOnTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.gradient,
    this.onTap,
  });

  final String label;
  final String value;
  final Gradient gradient;
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
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vcare.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
      ),
    );
  }
}
