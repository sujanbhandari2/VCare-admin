import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_status_chip.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_list_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class TodoTransactionDetailSheet extends ConsumerStatefulWidget {
  const TodoTransactionDetailSheet({super.key, required this.item});

  final TodoItem item;

  static Future<void> show(BuildContext context, {required TodoItem item}) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return SizedBox(
          height: height,
          child: TodoTransactionDetailSheet(item: item),
        );
      },
    );
  }

  @override
  ConsumerState<TodoTransactionDetailSheet> createState() =>
      _TodoTransactionDetailSheetState();
}

class _TodoTransactionDetailSheetState
    extends ConsumerState<TodoTransactionDetailSheet> {
  bool _reprocessing = false;

  TodoItem get item => widget.item;

  String? get _transactionId => item.transactionId;

  String get _reference {
    final invoice = item.paymentFailedDetails?.invoiceNumber?.trim();
    if (invoice != null && invoice.isNotEmpty) return invoice;
    return item.id;
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final details = item.paymentFailedDetails;
    final amountLabel = details == null
        ? '—'
        : NumberFormat.simpleCurrency(
            name: details.currency,
          ).format(details.amount);
    final canReprocess =
        _transactionId != null && _transactionId!.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              'Transaction details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reference',
                              style: TextStyle(
                                fontSize: 12,
                                color: vcare.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _reference,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClientStatusChip.transaction(
                        ClientTransactionStatus.failed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: vcare.border),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Billed to ${item.displayPayerName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                    ),
                  ),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Description',
                      child: Text(
                        item.description,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _DateCard(
                    icon: LucideIcons.calendarClock,
                    label: 'Occurred',
                    value: DateFormat(
                      'MMM d, yyyy, h:mm a',
                    ).format(item.occurredAt.toLocal()),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: vcare.border),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          color: vcare.mutedForeground,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        amountLabel,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
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
            child: OutlinedButton(
              onPressed: !canReprocess || _reprocessing
                  ? null
                  : _handleReprocess,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.rotateCw,
                    size: 16,
                    color: canReprocess && !_reprocessing
                        ? null
                        : vcare.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _reprocessing ? 'Reprocessing…' : 'Reprocess',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReprocess() async {
    final transactionId = _transactionId?.trim();
    if (transactionId == null || transactionId.isEmpty || _reprocessing) {
      return;
    }

    setState(() => _reprocessing = true);

    await ref
        .read(todoListStateProvider.notifier)
        .reprocessCharge(
          transactionId: transactionId,
          onCompleted: (success, _) {
            if (!mounted) return;

            setState(() => _reprocessing = false);

            if (success) {
              context.showVcareToast(
                title: 'Transaction reprocessed',
                description: _reference,
                variant: VcareToastVariant.success,
              );
              Navigator.of(context).pop();
            } else {
              context.showVcareToast(
                title: 'Reprocess failed',
                description: 'Try using a different payment method.',
                variant: VcareToastVariant.destructive,
              );
            }
          },
        );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: vcare.mutedForeground,
              ),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: vcare.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
