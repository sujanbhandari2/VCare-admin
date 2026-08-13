import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_button_styles.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/providers/pending_membership_detail_state_provider.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_approve_sheet.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_client_header.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_decline_sheet.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_section.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_summary_card.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_button_styles.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

/// Membership review sheet — parity with web `MembershipClientDrawer`.
class PendingMembershipDetailSheet extends ConsumerStatefulWidget {
  const PendingMembershipDetailSheet({super.key, required this.membership});

  /// Row the sheet was opened from; renders the header while detail loads.
  final PendingMembership membership;

  /// Resolves to `true` when the membership was approved or declined.
  static Future<bool?> show(
    BuildContext context, {
    required PendingMembership membership,
  }) {
    return context.showBottomSheet<bool>(
      isScrollControlled: true,
      maxHeightFactor: 0.94,
      builder: (sheetContext) =>
          PendingMembershipDetailSheet(membership: membership),
    );
  }

  @override
  ConsumerState<PendingMembershipDetailSheet> createState() =>
      _PendingMembershipDetailSheetState();
}

class _PendingMembershipDetailSheetState
    extends ConsumerState<PendingMembershipDetailSheet> {
  String get _membershipId => widget.membership.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(pendingMembershipDetailStateProvider(_membershipId).notifier)
          .load(bootstrap: widget.membership);
    });
  }

  Future<void> _approve(PendingMembership membership) async {
    final approved = await PendingMembershipApproveSheet.show(
      context,
      membership: membership,
    );
    if (approved != true || !mounted) return;
    context.pop(true);
  }

  Future<void> _decline(PendingMembership membership) async {
    final declined = await PendingMembershipDeclineSheet.show(
      context,
      membership: membership,
    );
    if (declined != true || !mounted) return;
    context.pop(true);
  }

  void _viewProfile(PendingMembership membership) {
    final clientId = membership.clientId.trim();
    if (clientId.isEmpty) return;

    context.pop();
    context.pushNamed(
      AppRouter.clientDetailName,
      pathParameters: {'id': clientId},
      queryParameters: {
        if (membership.client.clientType?.toUpperCase() == 'GROUP')
          'clientType': 'GROUP',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final state = ref.watch(
      pendingMembershipDetailStateProvider(_membershipId),
    );
    final membership = state.membership ?? widget.membership;
    final showActions = membership.status.isSubmitted;

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: state.hasDetailError
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: VcareErrorStatePanel(
                        title: 'Could not load membership details',
                        message: state.detailError,
                        actionLabel: 'Try again',
                        onAction: () => ref
                            .read(
                              pendingMembershipDetailStateProvider(
                                _membershipId,
                              ).notifier,
                            )
                            .load(bootstrap: widget.membership),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PendingMembershipClientHeader(
                          client: membership.client,
                          trailing: TextButton(
                            onPressed: () => _viewProfile(membership),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: vcare.primary,
                            ),
                            child: const Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PendingMembershipSummaryCard(
                                membership: membership,
                              ),
                              const SizedBox(height: 20),
                              PendingMembershipSection(
                                title: 'Associated memberships',
                                description:
                                    'Other enrollments tied to this client or '
                                    'their household.',
                                emptyMessage:
                                    'No other memberships are linked to this '
                                    'client or household.',
                                emptyIcon: LucideIcons.users,
                                memberships: state.associatedMemberships,
                                loading: state.associatedLoading,
                                hasError: state.associatedHasError,
                                onRetry: () => ref
                                    .read(
                                      pendingMembershipDetailStateProvider(
                                        _membershipId,
                                      ).notifier,
                                    )
                                    .loadAssociated(),
                              ),
                              const SizedBox(height: 20),
                              PendingMembershipSection(
                                title: 'Relevant memberships',
                                description:
                                    'Related enrollments in the same group or '
                                    'account.',
                                emptyMessage:
                                    'No related memberships in this group or '
                                    'account.',
                                emptyIcon: LucideIcons.layers,
                                memberships: state.relevantMemberships,
                                loading: state.relevantLoading,
                                hasError: state.relevantHasError,
                                showClientName: true,
                                hasMore: state.hasMoreRelevant,
                                remainingCount: state.remainingRelevantCount,
                                loadingMore: state.loadingMoreRelevant,
                                onLoadMore: () => ref
                                    .read(
                                      pendingMembershipDetailStateProvider(
                                        _membershipId,
                                      ).notifier,
                                    )
                                    .loadMoreRelevant(),
                                onRetry: () => ref
                                    .read(
                                      pendingMembershipDetailStateProvider(
                                        _membershipId,
                                      ).notifier,
                                    )
                                    .loadRelevant(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (showActions && !state.hasDetailError) ...[
            Divider(height: 1, color: vcare.border),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _decline(membership),
                      style: VCareButtonStyles.outlined(
                        foreground: vcare.destructive,
                        border: vcare.border,
                        background: Colors.transparent,
                        hoverBackground: vcare.destructive.withValues(
                          alpha: 0.08,
                        ),
                        hoverForeground: vcare.destructive,
                        size: VCareButtonSize.lg,
                      ),
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approve(membership),
                      style: pendingMembershipApproveButtonStyle(),
                      icon: const Icon(LucideIcons.checkCircle, size: 16),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
