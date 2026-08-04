import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Overview stat cards — parity with web [HomeMetricsSection].
class HomeMetricsSection extends StatelessWidget {
  const HomeMetricsSection({
    super.key,
    required this.isAgencyTied,
    required this.totalClients,
    required this.totalCommission,
    required this.totalSales,
    this.onTotalClientsTap,
    this.onSalesOrCommissionTap,
  });

  final bool isAgencyTied;
  final String totalClients;
  final String totalCommission;
  final String totalSales;
  final VoidCallback? onTotalClientsTap;
  final VoidCallback? onSalesOrCommissionTap;

  @override
  Widget build(BuildContext context) {
    final salesOrCommissionLabel = isAgencyTied
        ? 'Total Sales'
        : 'Total Commission';
    final salesOrCommissionValue = isAgencyTied
        ? totalSales
        : totalCommission;

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
                label: salesOrCommissionLabel,
                value: salesOrCommissionValue,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isAgencyTied
                      ? [
                          VCareColors.success.withValues(alpha: 0.15),
                          VCareColors.success.withValues(alpha: 0.05),
                        ]
                      : [
                          VCareColors.primary.withValues(alpha: 0.15),
                          VCareColors.primary.withValues(alpha: 0.05),
                        ],
                ),
                onTap: onSalesOrCommissionTap,
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
