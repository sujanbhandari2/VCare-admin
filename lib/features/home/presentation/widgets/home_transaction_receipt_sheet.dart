import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';

Future<void> showHomeTransactionReceiptSheet(
  BuildContext context,
  HomeTransaction transaction,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    barrierColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _TransactionReceiptSheet(
      transaction: transaction,
      heightFactor: transaction.status == 'Failed' ? 0.72 : 0.9,
    ),
  );
}

class _TransactionReceiptSheet extends StatelessWidget {
  const _TransactionReceiptSheet({
    required this.transaction,
    required this.heightFactor,
  });

  final HomeTransaction transaction;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isFailed = transaction.status == 'Failed';
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: vcare.muted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Text(
                isFailed ? 'Failed transaction' : 'Receipt',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFailed) ...[
                      _FailedBanner(transaction: transaction),
                      const SizedBox(height: 16),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _LabelValue(
                            label: 'Invoice',
                            value: '#${transaction.invoiceNumber}',
                          ),
                          _StatusPill(label: transaction.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      transaction.membership,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice ${transaction.invoiceNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: vcare.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.method,
                      style: TextStyle(
                        fontSize: 14,
                        color: vcare.mutedForeground,
                      ),
                    ),
                    if (!isFailed) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _LabelValue(
                              label: 'Service period',
                              value:
                                  '${_formatDate(transaction.periodStart)} - ${_formatDate(transaction.periodEnd)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabelValue(
                              label: 'Paid on',
                              value: _formatDateTime(transaction.paidAt),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    Divider(height: 1, color: vcare.border),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            isFailed ? 'Total due' : 'Total',
                            style: TextStyle(color: vcare.mutedForeground),
                          ),
                        ),
                        Text(
                          _formatMoney(transaction),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: vcare.border)),
              ),
              child: isFailed
                  ? _FailedActions(transaction: transaction)
                  : _DownloadAction(transaction: transaction),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedBanner extends StatelessWidget {
  const _FailedBanner({required this.transaction});

  final HomeTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final vcare = context.vcare;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.alertTriangle, size: 20, color: error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.failureReason == null
                      ? 'Payment failed'
                      : "Payment didn't go through",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: error,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${transaction.failureReason ?? 'Charge attempt was unsuccessful'} · ${transaction.method}',
                  style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedActions extends StatelessWidget {
  const _FailedActions({required this.transaction});

  final HomeTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SheetActionButton(
            icon: LucideIcons.creditCard,
            label: 'Update method',
            outlined: true,
            onTap: () =>
                _closeWithSnack(context, 'Payment method flow coming soon.'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SheetActionButton(
            icon: LucideIcons.mail,
            label: 'Contact',
            outlined: true,
            onTap: () =>
                _closeWithSnack(context, 'Support contact flow coming soon.'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SheetActionButton(
            icon: LucideIcons.refreshCw,
            label: 'Reprocess',
            onTap: () => _closeWithSnack(
              context,
              'Reprocessing ${transaction.membership}.',
            ),
          ),
        ),
      ],
    );
  }
}

class _DownloadAction extends StatelessWidget {
  const _DownloadAction({required this.transaction});

  final HomeTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () =>
            _closeWithSnack(context, 'PDF receipt download is coming soon.'),
        icon: const Icon(LucideIcons.download, size: 18),
        label: const Text('Download PDF receipt'),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );

    if (outlined) {
      return OutlinedButton(onPressed: onTap, child: child);
    }
    return FilledButton(onPressed: onTap, child: child);
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: VCareColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VCareColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: VCareColors.primary,
        ),
      ),
    );
  }
}

void _closeWithSnack(BuildContext context, String message) {
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _formatMoney(HomeTransaction transaction) {
  return NumberFormat.simpleCurrency(
    name: transaction.currency,
  ).format(transaction.amount);
}

String _formatDate(DateTime value) => DateFormat('MMM d, yyyy').format(value);

String _formatDateTime(DateTime value) =>
    DateFormat('MMM d, yyyy, h:mm a').format(value);
