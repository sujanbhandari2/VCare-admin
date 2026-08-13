import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_history_item.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

class CommissionDetailViewData {
  const CommissionDetailViewData({
    required this.clientName,
    required this.dateIso,
    required this.isAgencySale,
    this.saleAmount,
    this.commissionAmount,
    this.transactionId,
    this.notes,
    this.currency,
  });

  factory CommissionDetailViewData.fromHistory(CommissionHistoryItem item) {
    return CommissionDetailViewData(
      clientName: item.displayClientName,
      dateIso: item.displayDate,
      isAgencySale: false,
      saleAmount: item.salesAmount,
      commissionAmount: item.commissionAmount,
      transactionId: item.transactionId,
      notes: item.notes,
      currency: 'USD',
    );
  }

  factory CommissionDetailViewData.fromSale(SalesHistoryItem item) {
    return CommissionDetailViewData(
      clientName: item.displayPayerName,
      dateIso: item.transactionDate,
      isAgencySale: true,
      saleAmount: item.amount,
      commissionAmount: item.commissionAmount,
      transactionId: item.id,
      notes: null,
      currency: item.currency,
    );
  }

  final String clientName;
  final String dateIso;
  final bool isAgencySale;
  final double? saleAmount;
  final double? commissionAmount;
  final String? transactionId;
  final String? notes;
  final String? currency;
}

Future<void> showCommissionDetailSheet(
  BuildContext context,
  CommissionDetailViewData data,
) {
  return context.showBottomSheet<void>(
    isScrollControlled: true,
    builder: (sheetContext) => CommissionDetailSheet(data: data),
  );
}

class CommissionDetailSheet extends StatelessWidget {
  const CommissionDetailSheet({super.key, required this.data});

  final CommissionDetailViewData data;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final hasCommission = data.commissionAmount != null;
    final notes = data.notes?.trim();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            Text(
              data.isAgencySale ? 'Sale details' : 'Commission details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Client',
              style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
            ),
            const SizedBox(height: 2),
            Text(
              data.clientName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            if (data.isAgencySale)
              _AmountCard(
                label: 'Sale amount',
                value: formatCommissionMoney(
                  data.saleAmount,
                  currency: data.currency,
                ),
                subtitle: 'Commission is paid to your agency group.',
                accent: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    vcare.muted.withValues(alpha: 0.9),
                    vcare.muted.withValues(alpha: 0.4),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _AmountCard(
                      label: 'Sale',
                      value: formatCommissionMoney(
                        data.saleAmount,
                        currency: data.currency,
                      ),
                      accent: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          vcare.muted.withValues(alpha: 0.9),
                          vcare.muted.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AmountCard(
                      label: 'Commission',
                      value: hasCommission
                          ? formatCommissionMoney(
                              data.commissionAmount,
                              currency: data.currency,
                            )
                          : null,
                      subtitle: hasCommission
                          ? null
                          : 'Paid to your agency group.',
                      valueColor: hasCommission ? vcare.success : null,
                      accent: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          vcare.success.withValues(alpha: 0.15),
                          vcare.success.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: vcare.card,
                borderRadius: VCareRadius.xlAll,
                border: Border.all(color: vcare.border),
              ),
              child: Column(
                children: [
                  if (data.transactionId != null &&
                      data.transactionId!.trim().isNotEmpty) ...[
                    _DetailRow(
                      label: 'Transaction ID',
                      value: formatShortTransactionRef(data.transactionId),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                  ],
                  _DetailRow(
                    label: 'Date',
                    value: formatClientDateNumeric(data.dateIso),
                  ),
                  if (notes != null && notes.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _DetailRow(label: 'Notes', value: notes),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.label,
    required this.accent,
    this.value,
    this.subtitle,
    this.valueColor,
  });

  final String label;
  final String? value;
  final String? subtitle;
  final Color? valueColor;
  final Gradient accent;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: accent,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
            ),
            const SizedBox(height: 4),
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              )
            else if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: vcare.mutedForeground,
                ),
              ),
            if (value != null && subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
