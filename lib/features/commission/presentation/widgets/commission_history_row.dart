import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';

class CommissionHistoryRow extends StatelessWidget {
  const CommissionHistoryRow({super.key, required this.item, this.onTap});

  final CommissionHistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final title = item.displayClientName;
    final amount = formatCommissionMoney(item.commissionAmount, signed: true);
    final badgeLabel = commissionStatusLabel(item.status);

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatClientDateNumeric(item.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CommissionStatusBadge(label: badgeLabel, status: item.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommissionStatusBadge extends StatelessWidget {
  const CommissionStatusBadge({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final CommissionStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      CommissionStatus.paid => (
        VCareColors.primary,
        VCareColors.primaryForeground,
      ),
      CommissionStatus.pending => (
        VCareColors.secondary,
        VCareColors.secondaryForeground,
      ),
      CommissionStatus.cancelled => (
        VCareColors.destructive,
        VCareColors.destructiveForeground,
      ),
      CommissionStatus.unknown => (
        VCareColors.muted,
        VCareColors.mutedForeground,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class CommissionHistoryEmptyFilter extends StatelessWidget {
  const CommissionHistoryEmptyFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border, style: BorderStyle.solid),
      ),
      child: Text(
        'No commissions for this filter.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
      ),
    );
  }
}
