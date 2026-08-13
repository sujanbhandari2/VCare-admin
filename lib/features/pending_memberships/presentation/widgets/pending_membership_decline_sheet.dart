import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/core/styles/vcare_button_styles.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/providers/pending_membership_detail_state_provider.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_summary_card.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Decline reason capture — parity with web `MembershipDeclineDrawer`.
class PendingMembershipDeclineSheet extends ConsumerStatefulWidget {
  const PendingMembershipDeclineSheet({super.key, required this.membership});

  final PendingMembership membership;

  /// Resolves to `true` once the membership is declined.
  static Future<bool?> show(
    BuildContext context, {
    required PendingMembership membership,
  }) {
    return context.showBottomSheet<bool>(
      isScrollControlled: true,
      maxHeightFactor: 0.9,
      builder: (sheetContext) =>
          PendingMembershipDeclineSheet(membership: membership),
    );
  }

  @override
  ConsumerState<PendingMembershipDeclineSheet> createState() =>
      _PendingMembershipDeclineSheetState();
}

class _PendingMembershipDeclineSheetState
    extends ConsumerState<PendingMembershipDeclineSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    final declined = await ref
        .read(
          pendingMembershipDetailStateProvider(widget.membership.id).notifier,
        )
        .decline(
          note: reason,
          onError: (message) {
            if (!mounted) return;
            context.showVcareToast(
              title: 'Could not decline membership',
              description: message,
              variant: VcareToastVariant.destructive,
            );
          },
        );

    if (!declined || !mounted) return;

    context.showVcareToast(
      title: 'Membership declined',
      description: '${widget.membership.client.displayName} has been notified.',
      variant: VcareToastVariant.success,
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final submitting = ref.watch(
      pendingMembershipDetailStateProvider(
        widget.membership.id,
      ).select((state) => state.declining),
    );
    final canSubmit = _reasonController.text.trim().isNotEmpty && !submitting;

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Decline membership',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Provide a reason — it is shared with the client and saved on '
                  'the record.',
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
              padding: EdgeInsets.fromLTRB(20, 16, 20, keyboardInset + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PendingMembershipSummaryCard(membership: widget.membership),
                  const SizedBox(height: 16),
                  const Text(
                    'Reason for declining',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _reasonController,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 500,
                    enabled: !submitting,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          'Explain why this membership is being declined…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: vcare.mutedForeground,
                      ),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: VCareRadius.mdAll,
                        borderSide: BorderSide(color: vcare.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: VCareRadius.mdAll,
                        borderSide: BorderSide(color: vcare.border),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
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
                    onPressed: submitting ? null : () => context.pop(),
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
                  child: FilledButton(
                    onPressed: canSubmit ? _confirm : null,
                    style: VCareButtonStyles.filled(
                      background: vcare.destructive,
                      foreground: Colors.white,
                      size: VCareButtonSize.lg,
                      dimWhenDisabled: !submitting,
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Decline membership'),
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
