import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/features/home/utils/home_stats_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

/// parity: vcare-agent-app-2.0/src/features/commission/components/CommissionSummaryCard.tsx
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
      return VcareInlineErrorCard(message: error, onRetry: onRetry);
    }

    final totalSales = isLoading
        ? '—'
        : formatAgentStatMoney(summary?.totalSales);

    final upcomingSales = summary?.upcomingSales ?? 0;
    final upcomingCount = summary?.upcomingCount ?? 0;
    final needsAttentionSales = summary?.needsAttentionSales ?? 0;
    final needsAttentionCount = summary?.needsAttentionCount ?? 0;

    final showUpcoming = isLoading || upcomingSales > 0 || upcomingCount > 0;
    final showNeedsAttention =
        isLoading || needsAttentionSales > 0 || needsAttentionCount > 0;

    final upcomingSubtext = upcomingCount == 1
        ? '1 scheduled · not counted yet'
        : '$upcomingCount scheduled · not counted yet';
    final attentionSubtext = needsAttentionCount == 1
        ? '1 sale that failed to collect'
        : '$needsAttentionCount sales that failed to collect';

    final metrics = <Widget>[
      _CompactMetricCell(label: 'Total Sales', value: totalSales),
      if (!isAgencyGroup)
        _CompactMetricCell(
          label: 'Commission',
          value: isLoading
              ? '—'
              : formatAgentStatMoney(summary?.totalCommission),
          highlighted: true,
        ),
      if (showUpcoming)
        _CompactMetricCell(
          label: 'Upcoming',
          value: isLoading ? '—' : formatAgentStatMoney(upcomingSales),
          tone: _MetricTone.upcoming,
          subtext: isLoading ? null : upcomingSubtext,
        ),
      if (showNeedsAttention)
        _CompactMetricCell(
          label: 'Needs Attention',
          value: isLoading ? '—' : formatAgentStatMoney(needsAttentionSales),
          tone: _MetricTone.attention,
          subtext: isLoading ? null : attentionSubtext,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompactMetricStrip(children: metrics),
        if (isAgencyGroup) ...[
          const SizedBox(height: 8),
          const _AgencyInfoBanner(),
        ],
      ],
    );
  }
}

enum _MetricTone { normal, upcoming, attention }

class _AgencyInfoBanner extends StatelessWidget {
  const _AgencyInfoBanner();

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vcare.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 14, color: vcare.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Commissions are paid to your agency and distributed according to your agency's policy.",
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: vcare.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricStrip extends StatelessWidget {
  const _CompactMetricStrip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    if (children.length <= 2) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: vcare.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: vcare.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  VerticalDivider(width: 1, thickness: 1, color: vcare.border),
                Expanded(child: children[i]),
              ],
            ],
          ),
        ),
      );
    }

    // Wrap into a 2-column grid when Upcoming / Needs Attention appear.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        children: [
          for (var row = 0; row < children.length; row += 2) ...[
            if (row > 0) Divider(height: 1, thickness: 1, color: vcare.border),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: children[row]),
                  if (row + 1 < children.length) ...[
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: vcare.border,
                    ),
                    Expanded(child: children[row + 1]),
                  ] else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactMetricCell extends StatelessWidget {
  const _CompactMetricCell({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.tone = _MetricTone.normal,
    this.subtext,
  });

  final String label;
  final String value;
  final bool highlighted;
  final _MetricTone tone;
  final String? subtext;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final Color? bg;
    final Color valueColor;
    switch (tone) {
      case _MetricTone.upcoming:
        bg = const Color(0x14F97316);
        valueColor = const Color(0xFF9A3412);
      case _MetricTone.attention:
        bg = VCareColors.destructive.withValues(alpha: 0.08);
        valueColor = VCareColors.destructive;
      case _MetricTone.normal:
        bg = highlighted
            ? VCareColors.success.withValues(alpha: 0.06)
            : Colors.transparent;
        valueColor = VCareColors.foreground;
    }

    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.15,
                color: valueColor,
              ),
            ),
            if (subtext != null) ...[
              const SizedBox(height: 2),
              Text(
                subtext!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  color: vcare.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
