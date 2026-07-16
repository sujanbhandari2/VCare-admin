import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_transactions_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_status_chip.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_transaction_receipt_sheet.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class ClientTransactionDetailSheet extends ConsumerStatefulWidget {
  const ClientTransactionDetailSheet({
    super.key,
    required this.clientId,
    required this.transaction,
    required this.clientName,
    required this.clientEmail,
    required this.dependents,
    this.localNote,
    this.onNoteSaved,
  });

  final String clientId;
  final ClientTransaction transaction;
  final String clientName;
  final String clientEmail;
  final List<ClientDependent> dependents;
  final String? localNote;
  final ValueChanged<String>? onNoteSaved;

  static Future<void> show(
    BuildContext context, {
    required String clientId,
    required ClientTransaction transaction,
    required String clientName,
    required String clientEmail,
    required List<ClientDependent> dependents,
    String? localNote,
    ValueChanged<String>? onNoteSaved,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.92;
        return SizedBox(
          height: height,
          child: ClientTransactionDetailSheet(
            clientId: clientId,
            transaction: transaction,
            clientName: clientName,
            clientEmail: clientEmail,
            dependents: dependents,
            localNote: localNote,
            onNoteSaved: onNoteSaved,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<ClientTransactionDetailSheet> createState() =>
      _ClientTransactionDetailSheetState();
}

class _ClientTransactionDetailSheetState
    extends ConsumerState<ClientTransactionDetailSheet> {
  late String? _localNote = widget.localNote;
  bool _reprocessing = false;

  bool get _isFailed =>
      widget.transaction.status == ClientTransactionStatus.failed;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final transaction = widget.transaction;
    final note = transaction.note;
    final savedNote = _localNote;
    final hasNotes =
        (note != null && note.trim().isNotEmpty) ||
        (savedNote != null && savedNote.trim().isNotEmpty);

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
                              transaction.reference,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClientStatusChip.transaction(transaction.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: vcare.border),
                  const SizedBox(height: 16),
                  Text(
                    transaction.membershipTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Billed to ${widget.clientName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                    ),
                  ),
                  if (transaction.dependentName != null) ...[
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                        children: [
                          const TextSpan(text: 'Dependent: '),
                          TextSpan(
                            text: transaction.dependentName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (transaction.dependentRelation != null &&
                              transaction.dependentRelation != 'Self')
                            TextSpan(
                              text: ' (${transaction.dependentRelation})',
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (transaction.paymentMethodLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.paymentMethodLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                  if (transaction.description != null &&
                      transaction.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Description',
                      child: Text(
                        transaction.description!,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                  if (widget.dependents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _BreakdownCard(
                      clientName: widget.clientName,
                      dependents: widget.dependents,
                      total: transaction.amount,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DateCard(
                          icon: LucideIcons.calendarClock,
                          label: 'Transaction',
                          value: transaction.dateTime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateCard(
                          icon: LucideIcons.calendarCheck,
                          label: 'Pay date',
                          value: transaction.payDate,
                        ),
                      ),
                    ],
                  ),
                  if (hasNotes) ...[
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Notes',
                      leading: Icon(
                        LucideIcons.alignLeft,
                        size: 14,
                        color: vcare.mutedForeground,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (note != null && note.trim().isNotEmpty)
                            Text(note, style: const TextStyle(fontSize: 14)),
                          if (savedNote != null &&
                              savedNote.trim().isNotEmpty) ...[
                            if (note != null && note.trim().isNotEmpty)
                              const SizedBox(height: 4),
                            Text(
                              savedNote,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
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
                        '\$${transaction.amount.toStringAsFixed(2)}',
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
            child: Row(
              children: [
                if (_isFailed) ...[
                  Expanded(
                    child: _TxnActionButton(
                      icon: LucideIcons.rotateCw,
                      label: _reprocessing ? 'Reprocessing…' : 'Reprocess',
                      onTap: _reprocessing ? null : _handleReprocess,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _TxnActionButton(
                    icon: LucideIcons.receipt,
                    label: 'Receipt',
                    onTap: _openReceipt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TxnActionButton(
                    icon: LucideIcons.stickyNote,
                    label: 'Add note',
                    onTap: _openAddNote,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TxnActionButton(
                    icon: LucideIcons.send,
                    label: 'Email',
                    onTap: _openEmailReceipt,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReprocess() async {
    if (_reprocessing) return;

    setState(() => _reprocessing = true);

    await ref
        .read(clientTransactionsStateProvider(widget.clientId).notifier)
        .reprocessCharge(
          transactionId: widget.transaction.id,
          onCompleted: (success, error) {
            if (!mounted) return;

            setState(() => _reprocessing = false);

            if (success) {
              context.showVcareToast(
                title: 'Transaction reprocessed',
                description: widget.transaction.reference,
                variant: VcareToastVariant.success,
              );
              Navigator.of(context).pop();
            } else {
              context.showVcareToast(
                title: 'Reprocess failed',
                description: error ?? 'Unable to reprocess this transaction.',
                variant: VcareToastVariant.destructive,
              );
            }
          },
        );
  }

  void _openReceipt() {
    ClientTransactionReceiptSheet.show(
      context,
      receipt: ClientTransactionReceiptInfo.fromTransaction(
        transaction: widget.transaction,
        payerName: widget.clientName,
      ),
    );
  }

  Future<void> _openAddNote() async {
    final note = await _AddNoteSheet.show(context);
    if (note == null || !mounted) return;

    setState(() => _localNote = note);
    widget.onNoteSaved?.call(note);
    context.showVcareToast(
      title: 'Note saved',
      variant: VcareToastVariant.success,
    );
  }

  Future<void> _openEmailReceipt() async {
    final email = await _EmailReceiptSheet.show(
      context,
      initialEmail: widget.clientEmail,
    );
    if (email == null || !mounted) return;

    context.showVcareToast(
      title: 'Receipt emailed',
      description: email,
      variant: VcareToastVariant.success,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child, this.leading});

  final String title;
  final Widget child;
  final Widget? leading;

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
            Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 4)],
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: vcare.mutedForeground,
                  ),
                ),
              ],
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

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.clientName,
    required this.dependents,
    required this.total,
  });

  final String clientName;
  final List<ClientDependent> dependents;
  final double total;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final covered = <({String name, String relation})>[
      (name: clientName, relation: 'Self'),
      ...dependents.map((d) => (name: d.name, relation: d.relation)),
    ];
    final per = (total / covered.length * 100).floor() / 100;
    final parts = List.generate(covered.length, (index) {
      final amount = index == covered.length - 1
          ? double.parse((total - per * (covered.length - 1)).toStringAsFixed(2))
          : per;
      return (part: covered[index], amount: amount);
    });

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
              'BREAKDOWN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: vcare.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            ...parts.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: entry.part.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' · ${entry.part.relation}',
                              style: TextStyle(
                                fontSize: 14,
                                color: vcare.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${entry.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 16, color: vcare.border),
            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TxnActionButton extends StatelessWidget {
  const _TxnActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AddNoteSheet extends StatefulWidget {
  const _AddNoteSheet();

  static Future<String?> show(BuildContext context) {
    return context.showBottomSheet<String>(
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: const _AddNoteSheet(),
        );
      },
    );
  }

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              'Add note',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add a note for this transaction…',
                filled: true,
                fillColor: vcare.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: vcare.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: vcare.border),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: vcare.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    text: 'Cancel',
                    height: 44,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.elevated(
                    text: 'Save note',
                    height: 44,
                    borderRadius: BorderRadius.circular(12),
                    color: VCareColors.primary,
                    onButtonColor: VCareColors.primaryForeground,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailReceiptSheet extends StatefulWidget {
  const _EmailReceiptSheet({required this.initialEmail});

  final String initialEmail;

  static Future<String?> show(
    BuildContext context, {
    required String initialEmail,
  }) {
    return context.showBottomSheet<String>(
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _EmailReceiptSheet(initialEmail: initialEmail),
        );
      },
    );
  }

  @override
  State<_EmailReceiptSheet> createState() => _EmailReceiptSheetState();
}

class _EmailReceiptSheetState extends State<_EmailReceiptSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialEmail,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              'Email receipt',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send a copy of this receipt to the recipient below.',
                  style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
                ),
                const SizedBox(height: 12),
                Text(
                  'RECIPIENT EMAIL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: vcare.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    filled: true,
                    fillColor: vcare.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: vcare.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: vcare.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: vcare.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    text: 'Cancel',
                    height: 44,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.elevated(
                    text: 'Confirm & send',
                    height: 44,
                    borderRadius: BorderRadius.circular(12),
                    color: VCareColors.primary,
                    onButtonColor: VCareColors.primaryForeground,
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
