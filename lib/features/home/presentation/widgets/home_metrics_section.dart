import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Overview stat cards — parity with vcareapp [HomeMetricsSection].
class HomeMetricsSection extends StatefulWidget {
  const HomeMetricsSection({
    super.key,
    this.totalClients = '10',
    this.totalCommission = r'$12,480',
    this.totalSales = r'$124,800',
    this.onTotalClientsTap,
    this.onCommissionTap,
  });

  final String totalClients;
  final String totalCommission;
  final String totalSales;
  final VoidCallback? onTotalClientsTap;
  final VoidCallback? onCommissionTap;

  @override
  State<HomeMetricsSection> createState() => _HomeMetricsSectionState();
}

class _HomeMetricsSectionState extends State<HomeMetricsSection> {
  bool _showSales = false;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              _showSales ? 'Sales stats' : 'Commission stats',
              style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
            ),
            const SizedBox(width: 8),
            Material(
              color: vcare.muted,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => setState(() => _showSales = !_showSales),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    _showSales ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 14,
                    color: vcare.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Clients',
                value: widget.totalClients,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x26F59E0B), Color(0x0DF59E0B)],
                ),
                onTap: widget.onTotalClientsTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: _showSales ? 'Total Sales' : 'Total Commission',
                value: _showSales ? widget.totalSales : widget.totalCommission,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VCareColors.primary.withValues(alpha: 0.15),
                    VCareColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                onTap: widget.onCommissionTap,
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
