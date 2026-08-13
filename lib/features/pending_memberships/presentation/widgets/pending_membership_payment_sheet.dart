import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_payment_methods_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_add_payment_method_sheet.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Payment method on file for the client being charged — parity with web
/// `ApprovalPaymentDrawer`. Selecting a method makes it the primary card, which
/// is what the approval charge uses.
class PendingMembershipPaymentSheet extends ConsumerStatefulWidget {
  const PendingMembershipPaymentSheet({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  final String clientId;
  final String clientName;

  static Future<void> show(
    BuildContext context, {
    required String clientId,
    required String clientName,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      maxHeightFactor: 0.85,
      builder: (sheetContext) => PendingMembershipPaymentSheet(
        clientId: clientId,
        clientName: clientName,
      ),
    );
  }

  @override
  ConsumerState<PendingMembershipPaymentSheet> createState() =>
      _PendingMembershipPaymentSheetState();
}

class _PendingMembershipPaymentSheetState
    extends ConsumerState<PendingMembershipPaymentSheet> {
  String? _updatingId;

  Future<void> _selectMethod(ClientPaymentMethod method) async {
    if (method.isPrimary || _updatingId != null) return;

    setState(() => _updatingId = method.id);

    await ref
        .read(clientPaymentMethodsStateProvider(widget.clientId).notifier)
        .setPrimary(
          paymentMethodId: method.id,
          onCompleted: (success, error) {
            if (!mounted) return;
            if (success) {
              context.showVcareToast(
                title: 'Payment method updated',
                description: '${method.label} will be charged on approval.',
                variant: VcareToastVariant.success,
              );
              return;
            }
            context.showVcareToast(
              title: 'Could not update payment method',
              description: error,
              variant: VcareToastVariant.destructive,
            );
          },
        );

    if (mounted) setState(() => _updatingId = null);
  }

  Future<void> _addMethod() async {
    await ClientAddPaymentMethodSheet.show(context, clientId: widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final methodsState = ref.watch(
      clientPaymentMethodsStateProvider(widget.clientId),
    );
    final methods = methodsState.methods;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose which card on file is charged for '
                  '${widget.clientName}.',
                  style: TextStyle(
                    fontSize: 12,
                    color: vcare.mutedForeground,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: vcare.border),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (methodsState.isInitialLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (methods.isEmpty)
                    Text(
                      'No payment methods on file yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: vcare.mutedForeground,
                      ),
                    )
                  else
                    for (final method in methods) ...[
                      _PaymentMethodTile(
                        method: method,
                        updating: _updatingId == method.id,
                        onTap: () => _selectMethod(method),
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _addMethod,
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add payment method'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.updating,
    required this.onTap,
  });

  final ClientPaymentMethod method;
  final bool updating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final selected = method.isPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: updating ? null : onTap,
        borderRadius: VCareRadius.lgAll,
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? vcare.primary.withValues(alpha: 0.06)
                : vcare.card,
            borderRadius: VCareRadius.lgAll,
            border: Border.all(
              color: selected ? vcare.primary : vcare.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  LucideIcons.creditCard,
                  size: 18,
                  color: vcare.mutedForeground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selected)
                        Text(
                          'Primary',
                          style: TextStyle(
                            fontSize: 11,
                            color: vcare.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                ),
                if (updating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (selected)
                  Icon(LucideIcons.check, size: 16, color: vcare.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
