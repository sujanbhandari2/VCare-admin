import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_payment_methods_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_add_payment_method_sheet.dart';
import 'package:vcare_admin/features/help_support/presentation/widgets/contact_support_sheet.dart';
import 'package:vcare_admin/features/home/data/home_activity_builder.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_activity_status_chip.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_list_state_provider.dart';
import 'package:vcare_admin/features/todo/utils/failed_payment_copy.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Recovery sheet for `PAYMENT_FAILED` todos — parity with web `FailedPaymentSheet`.
class TodoTransactionDetailSheet extends ConsumerStatefulWidget {
  const TodoTransactionDetailSheet({super.key, required this.item});

  final TodoItem item;

  static Future<void> show(BuildContext context, {required TodoItem item}) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.92;
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
  String? _selectedCardId;
  String? _chargingId;
  String? _chargeError;
  var _settingPrimary = false;

  TodoItem get item => widget.item;

  TodoPaymentFailedDetails? get _details => item.paymentFailedDetails;

  String? get _transactionId => item.transactionId;

  String get _payerId => _details?.payerId.trim() ?? '';

  String get _payerName => item.displayPayerName;

  String get _amountLabel {
    final details = _details;
    if (details == null) return '—';
    return NumberFormat.simpleCurrency(
      name: details.currency,
    ).format(details.amount);
  }

  FailedPaymentCopy get _copy =>
      getFailedPaymentCopy(_details?.failureReason, _payerName);

  bool get _isBusy => _settingPrimary || _chargingId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _payerId.isEmpty) return;
      ref
          .read(clientPaymentMethodsStateProvider(_payerId).notifier)
          .fetchPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final methodsState = _payerId.isEmpty
        ? const ClientPaymentMethodsStateData()
        : ref.watch(clientPaymentMethodsStateProvider(_payerId));
    final methods = methodsState.methods;
    ClientPaymentMethod? primaryMethod;
    for (final method in methods) {
      if (method.isPrimary) {
        primaryMethod = method;
        break;
      }
    }
    final primary = primaryMethod;
    final otherCards = methods.where((m) => !m.isPrimary).toList();

    if (_selectedCardId != null &&
        !otherCards.any((m) => m.id == _selectedCardId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCardId = null);
      });
    }

    final bannerExplanation = primary?.last4 != null
        ? "$_payerName's primary card ending ${primary!.last4} couldn't be charged."
        : _copy.explanation;

    final pathCount =
        1 + (otherCards.isNotEmpty ? 1 : 0) + (primary != null ? 1 : 0);
    final recoverHint = pathCount >= 3
        ? 'Choose whichever one works — all three recover $_amountLabel.'
        : 'Choose whichever one works — recover $_amountLabel.';

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
              "We couldn't process this payment",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Divider(height: 1, color: vcare.border),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FailureBanner(
                    amountLabel: _amountLabel,
                    shortLabel: _copy.shortLabel,
                    whenLabel: formatWhen(item.occurredAt),
                    explanation: bannerExplanation,
                  ),
                  const SizedBox(height: 20),
                  if (methodsState.isInitialLoading)
                    const _MethodsSkeleton()
                  else if (methodsState.error != null && methods.isEmpty)
                    _MethodsError(
                      payerName: _payerName,
                      onRetry: () {
                        ref
                            .read(
                              clientPaymentMethodsStateProvider(
                                _payerId,
                              ).notifier,
                            )
                            .fetchPaymentMethods();
                      },
                    )
                  else ...[
                    Text(
                      'RECOVER THIS PAYMENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: vcare.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recoverHint,
                      style: TextStyle(
                        fontSize: 11,
                        color: vcare.mutedForeground,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (otherCards.isNotEmpty) ...[
                      _RecoveryCard(
                        title: 'Charge a card on file',
                        subtitle: "Use one of $_payerName's other saved cards.",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final method in otherCards) ...[
                              _CardSelectTile(
                                method: method,
                                selected: _selectedCardId == method.id,
                                onTap: _isBusy
                                    ? null
                                    : () => setState(
                                        () => _selectedCardId = method.id,
                                      ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            OutlinedButton(
                              onPressed: _isBusy || _selectedCardId == null
                                  ? null
                                  : () => _chargeSelected(otherCards),
                              style: _recoveryButtonStyle(),
                              child: Text(
                                _chargingId != null &&
                                        _chargingId == _selectedCardId
                                    ? 'Processing…'
                                    : 'Charge $_amountLabel',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _OrDivider(),
                    ],
                    _RecoveryCard(
                      title: 'Add a card',
                      subtitle:
                          'Saved to $_payerName\'s account and charged $_amountLabel.',
                      child: OutlinedButton(
                        onPressed: _isBusy ? null : _openAddCard,
                        style: _recoveryButtonStyle(),
                        child: const Text(
                          'Add card & charge',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (primary != null) ...[
                      const _OrDivider(),
                      _RecoveryCard(
                        title: 'Try the same card again',
                        subtitle:
                            'Worth a shot if the decline was only temporary.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CardSummaryTile(method: primary),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _isBusy
                                  ? null
                                  : () => _retryPrimary(primary),
                              style: _recoveryButtonStyle(),
                              child: Text(
                                _chargingId == primary.id && _isBusy
                                    ? 'Processing…'
                                    : 'Retry payment',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  if (_chargeError != null) ...[
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: VCareColors.destructive.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: VCareColors.destructive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          _chargeError!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Still not working? '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: _isBusy ? null : _contactSupport,
                            child: Text(
                              'Contact support',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: VCareColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _recoveryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: VCareColors.primary,
      backgroundColor: VCareColors.primary.withValues(alpha: 0.1),
      side: BorderSide(color: VCareColors.primary.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _openAddCard() async {
    final payerId = _payerId;
    if (payerId.isEmpty) return;

    await ClientAddPaymentMethodSheet.show(
      context,
      clientId: payerId,
      submitLabel: 'Save and pay $_amountLabel',
      onAdded: _handleCardAddedAndPay,
    );
  }

  Future<void> _handleCardAddedAndPay(ClientPaymentMethod method) async {
    if (!mounted) return;
    setState(() => _chargeError = null);
    try {
      await _chargeWithCard(method);
      if (!mounted) return;
      _finishSuccess();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _chargeError = error is _ChargeFailedException
            ? error.message
            : "Card was saved, but the payment didn't go through. Try retrying or another card.";
      });
    }
  }

  Future<void> _chargeSelected(List<ClientPaymentMethod> otherCards) async {
    ClientPaymentMethod? method;
    for (final candidate in otherCards) {
      if (candidate.id == _selectedCardId) {
        method = candidate;
        break;
      }
    }
    final selected = method;
    if (selected == null || _isBusy) return;

    setState(() {
      _chargeError = null;
      _chargingId = selected.id;
    });

    try {
      await _chargeWithCard(selected);
      if (!mounted) return;
      _finishSuccess();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _chargeError = error is _ChargeFailedException
            ? error.message
            : "Payment didn't go through. Try a different card on the client's file.";
        _chargingId = null;
      });
    }
  }

  Future<void> _retryPrimary(ClientPaymentMethod primary) async {
    if (_isBusy) return;
    final transactionId = _transactionId?.trim();
    if (transactionId == null || transactionId.isEmpty) return;

    setState(() {
      _chargeError = null;
      _chargingId = primary.id;
    });

    try {
      await _chargeOnly(transactionId);
      if (!mounted) return;
      _finishSuccess();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _chargeError = error is _ChargeFailedException
            ? error.message
            : "Payment didn't go through. Try another of the client's cards.";
        _chargingId = null;
      });
    }
  }

  Future<void> _chargeWithCard(ClientPaymentMethod method) async {
    final transactionId = _transactionId?.trim();
    if (transactionId == null || transactionId.isEmpty) {
      throw const _ChargeFailedException('Missing transaction.');
    }

    if (!method.isPrimary) {
      setState(() => _settingPrimary = true);
      final setPrimaryOk = await _setPrimary(method.id);
      if (mounted) setState(() => _settingPrimary = false);
      if (!setPrimaryOk) {
        throw const _ChargeFailedException(
          "Couldn't set that card as primary. Try again.",
        );
      }
    }

    await _chargeOnly(transactionId);
  }

  Future<bool> _setPrimary(String paymentMethodId) async {
    final payerId = _payerId;
    if (payerId.isEmpty) return false;

    var ok = false;
    await ref
        .read(clientPaymentMethodsStateProvider(payerId).notifier)
        .setPrimary(
          paymentMethodId: paymentMethodId,
          onCompleted: (success, _) {
            ok = success;
          },
        );
    return ok;
  }

  Future<void> _chargeOnly(String transactionId) async {
    var success = false;
    String? error;
    await ref
        .read(todoListStateProvider.notifier)
        .reprocessCharge(
          transactionId: transactionId,
          onCompleted: (ok, message) {
            success = ok;
            error = message;
          },
        );

    if (!success) {
      throw _ChargeFailedException(
        error?.trim().isNotEmpty == true
            ? error!.trim()
            : "Payment didn't go through. Try a different card on the client's file.",
      );
    }
  }

  void _finishSuccess() {
    context.showVcareToast(
      title: 'Payment of $_amountLabel went through',
      variant: VcareToastVariant.success,
    );
    Navigator.of(context).pop();
  }

  void _contactSupport() {
    // parity: FailedPaymentSheet → ContactSupportDialog
    ContactSupportSheet.show(
      context,
      subject: 'Payment Failed',
      contextPayload: {
        'page': 'failed-payment',
        'transactionId': _transactionId,
        'payerId': _payerId,
        'payerName': _payerName,
        'membershipName': null,
        'amount': _amountLabel,
      },
    );
  }
}

class _ChargeFailedException implements Exception {
  const _ChargeFailedException(this.message);
  final String message;
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({
    required this.amountLabel,
    required this.shortLabel,
    required this.whenLabel,
    required this.explanation,
  });

  final String amountLabel;
  final String shortLabel;
  final String whenLabel;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.alertTriangle, size: 16, color: error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          amountLabel,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: error,
                          ),
                        ),
                      ),
                      HomeActivityStatusChip(
                        label: '$shortLabel · $whenLabel',
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    explanation,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: context.vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodsSkeleton extends StatelessWidget {
  const _MethodsSkeleton();

  @override
  Widget build(BuildContext context) {
    final muted = context.vcare.muted.withValues(alpha: 0.5);
    return Column(
      children: [
        for (final height in [112.0, 96.0, 96.0]) ...[
          Container(
            height: height,
            decoration: BoxDecoration(
              color: muted,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MethodsError extends StatelessWidget {
  const _MethodsError({required this.payerName, required this.onRetry});

  final String payerName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 13, color: error, height: 1.35),
            children: [
              TextSpan(text: "Couldn't load $payerName's cards. "),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: onRetry,
                  child: Text(
                    'Try again',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: error,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: vcare.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: vcare.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: vcare.mutedForeground,
              ),
            ),
          ),
          Expanded(child: Divider(height: 1, color: vcare.border)),
        ],
      ),
    );
  }
}

class _CardSelectTile extends StatelessWidget {
  const _CardSelectTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final ClientPaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: selected
          ? VCareColors.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? VCareColors.primary.withValues(alpha: 0.4)
              : vcare.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2,
                    color: selected
                        ? VCareColors.primary
                        : vcare.mutedForeground.withValues(alpha: 0.4),
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: VCareColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: _CardSummaryContent(method: method)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSummaryTile extends StatelessWidget {
  const _CardSummaryTile({required this.method});

  final ClientPaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: _CardSummaryContent(method: method),
      ),
    );
  }
}

class _CardSummaryContent extends StatelessWidget {
  const _CardSummaryContent({required this.method});

  final ClientPaymentMethod method;

  String get _last4Display {
    final last4 = method.last4?.trim();
    if (last4 != null && last4.isNotEmpty) return '•••• $last4';
    final match = RegExp(r'(\d{4})\s*$').firstMatch(method.label);
    if (match != null) return '•••• ${match.group(1)}';
    return method.label;
  }

  String get _expiry {
    final month = method.expMonth;
    final year = method.expYear;
    if (month == null || year == null) return 'Expiry unavailable';
    final yy = year.toString().length >= 2
        ? year.toString().substring(year.toString().length - 2)
        : year.toString();
    return 'Expires ${month.toString().padLeft(2, '0')}/$yy';
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: vcare.muted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            LucideIcons.creditCard,
            size: 16,
            color: vcare.mutedForeground,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _last4Display,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _expiry,
                style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
