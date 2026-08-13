import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_button_styles.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_payment_methods_state_provider.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/membership_approval.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/providers/pending_membership_approval_state_provider.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_approval_items.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_payment_sheet.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_button_styles.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_formatters.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_option_picker_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Approval review and confirm — parity with web `ApprovalFlowContent`
/// (billing start selection, pricing preview, payment method, approve).
class PendingMembershipApproveSheet extends ConsumerStatefulWidget {
  const PendingMembershipApproveSheet({super.key, required this.membership});

  final PendingMembership membership;

  /// Resolves to `true` once the membership is approved.
  static Future<bool?> show(
    BuildContext context, {
    required PendingMembership membership,
  }) {
    return context.showBottomSheet<bool>(
      isScrollControlled: true,
      maxHeightFactor: 0.94,
      builder: (sheetContext) =>
          PendingMembershipApproveSheet(membership: membership),
    );
  }

  @override
  ConsumerState<PendingMembershipApproveSheet> createState() =>
      _PendingMembershipApproveSheetState();
}

class _PendingMembershipApproveSheetState
    extends ConsumerState<PendingMembershipApproveSheet> {
  String? _paymentClientId;

  String get _membershipId => widget.membership.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(pendingMembershipApprovalStateProvider(_membershipId).notifier)
          .initialize();
    });
  }

  void _syncPaymentMethods(MembershipApprovalCompute? compute) {
    final clientId = compute?.billingClientId;
    if (clientId == null || clientId == _paymentClientId) return;

    _paymentClientId = clientId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(clientPaymentMethodsStateProvider(clientId).notifier)
          .fetchPaymentMethods();
    });
  }

  Future<void> _pickBillingStart(
    List<MembershipBillingStartOption> options,
  ) async {
    final selected = await VcareOptionPickerSheet.show<String>(
      context,
      title: 'Billing starts',
      options: options.map((option) => option.value).toList(growable: false),
      labelOf: (value) =>
          options.firstWhere((option) => option.value == value).label,
      selected: ref
          .read(pendingMembershipApprovalStateProvider(_membershipId))
          .selectedBillingStart,
    );

    if (selected == null || !mounted) return;

    await ref
        .read(pendingMembershipApprovalStateProvider(_membershipId).notifier)
        .selectBillingStart(selected);
  }

  Future<void> _approve(int membershipCount, String clientName) async {
    final approved = await ref
        .read(pendingMembershipApprovalStateProvider(_membershipId).notifier)
        .approve(
          onError: (message) {
            if (!mounted) return;
            context.showVcareToast(
              title: 'Approval failed',
              description: message,
              variant: VcareToastVariant.destructive,
            );
          },
        );

    if (approved == null || !mounted) return;

    context.showVcareToast(
      title: 'Membership approved',
      description: membershipCount > 1
          ? '$membershipCount memberships approved for $clientName.'
          : 'Membership approved for $clientName.',
      variant: VcareToastVariant.success,
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final state = ref.watch(
      pendingMembershipApprovalStateProvider(_membershipId),
    );
    final compute = state.compute;
    _syncPaymentMethods(compute);

    final clientName =
        compute?.billingClientName ?? widget.membership.client.displayName;
    final membershipCount = compute?.membershipCount ?? 1;
    final billingClientId = compute?.billingClientId;
    final benefitStart = compute?.resolveBenefitStartDate(
      state.selectedOption?.date ?? DateTime.now(),
    );

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Text(
              'Approve membership',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Divider(height: 1, color: vcare.border),
          Expanded(
            child: state.isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : state.hasError
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: VcareErrorStatePanel(
                      title: 'Unable to price this approval',
                      message: state.error,
                      actionLabel: 'Try again',
                      onAction: () => ref
                          .read(
                            pendingMembershipApprovalStateProvider(
                              _membershipId,
                            ).notifier,
                          )
                          .initialize(),
                    ),
                  )
                : compute == null || state.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'This membership is no longer awaiting approval.',
                      style: TextStyle(
                        fontSize: 13,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ApprovalIntro(
                          membershipCount: membershipCount,
                          clientName: clientName,
                          benefitStartDate: benefitStart,
                        ),
                        const SizedBox(height: 12),
                        _ApprovalSetupCard(
                          billingStartLabel: state.selectedOption?.label,
                          onPickBillingStart: state.billingStartOptions.isEmpty
                              ? null
                              : () => _pickBillingStart(
                                  state.billingStartOptions,
                                ),
                          paymentLabel: billingClientId == null
                              ? null
                              : _paymentLabel(billingClientId),
                          onPickPayment: billingClientId == null
                              ? null
                              : () => PendingMembershipPaymentSheet.show(
                                  context,
                                  clientId: billingClientId,
                                  clientName: clientName,
                                ),
                          note: billingClientId == null
                              ? 'Billing is managed on the primary account. '
                                    'Payment details are not sent with approval.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Charges',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        PendingMembershipApprovalItems(
                          compute: compute,
                          dimmed: state.isRepricing,
                        ),
                      ],
                    ),
                  ),
          ),
          Divider(height: 1, color: vcare.border),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.approving ? null : () => context.pop(),
                    style: VCareButtonStyles.outlined(
                      foreground: vcare.foreground,
                      border: vcare.border,
                      background: Colors.transparent,
                      hoverBackground: vcare.muted,
                      hoverForeground: vcare.foreground,
                      size: VCareButtonSize.lg,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: state.canApprove
                        ? () => _approve(membershipCount, clientName)
                        : null,
                    style: pendingMembershipApproveButtonStyle(
                      dimWhenDisabled: !state.approving,
                    ),
                    icon: state.approving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.checkCircle, size: 16),
                    label: Text(
                      state.approving
                          ? 'Approving…'
                          : compute == null
                          ? 'Approve'
                          : 'Approve · '
                                '${formatMembershipMoney(compute.grandTotal, currency: compute.currency)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _paymentLabel(String clientId) {
    final methods = ref
        .watch(clientPaymentMethodsStateProvider(clientId))
        .methods;
    if (methods.isEmpty) return 'Add a card';

    for (final method in methods) {
      if (method.isPrimary) return method.label;
    }
    return methods.first.label;
  }
}

class _ApprovalIntro extends StatelessWidget {
  const _ApprovalIntro({
    required this.membershipCount,
    required this.clientName,
    required this.benefitStartDate,
  });

  final int membershipCount;
  final String clientName;
  final DateTime? benefitStartDate;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final membershipLabel = membershipCount == 1
        ? '1 membership'
        : '$membershipCount memberships';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 14, height: 1.4),
            children: [
              const TextSpan(text: 'You are approving '),
              TextSpan(
                text: membershipLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: ' for '),
              TextSpan(
                text: clientName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: ', with benefits starting on ',
                style: TextStyle(color: vcare.mutedForeground),
              ),
              TextSpan(
                text: formatMembershipDate(benefitStartDate),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: '.',
                style: TextStyle(color: vcare.mutedForeground),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Review the charges below, then approve when ready.',
          style: TextStyle(
            fontSize: 12,
            color: vcare.mutedForeground,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ApprovalSetupCard extends StatelessWidget {
  const _ApprovalSetupCard({
    required this.billingStartLabel,
    required this.onPickBillingStart,
    required this.paymentLabel,
    required this.onPickPayment,
    required this.note,
  });

  final String? billingStartLabel;
  final VoidCallback? onPickBillingStart;
  final String? paymentLabel;
  final VoidCallback? onPickPayment;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.35),
        borderRadius: VCareRadius.lgAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (billingStartLabel != null)
              _SetupRow(
                icon: LucideIcons.calendar,
                label: 'Billing starts',
                value: billingStartLabel!,
                onTap: onPickBillingStart,
              ),
            if (paymentLabel != null)
              _SetupRow(
                icon: LucideIcons.creditCard,
                label: 'Payment',
                value: paymentLabel!,
                onTap: onPickPayment,
              ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  note!,
                  style: TextStyle(
                    fontSize: 11,
                    color: vcare.mutedForeground,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  const _SetupRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            children: [
              Icon(icon, size: 15, color: vcare.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: vcare.mutedForeground,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
