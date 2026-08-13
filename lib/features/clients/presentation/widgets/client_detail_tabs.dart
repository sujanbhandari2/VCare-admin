import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/state/client_documents_loadable_state.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_payment_methods_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_add_payment_method_sheet.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_contact_card.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_create_case_sheet.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_detail_carousel.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_detail_section_heading.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_status_chip.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_upload_document_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class ClientMembershipsTab extends StatelessWidget {
  const ClientMembershipsTab({
    super.key,
    required this.memberships,
    required this.dependents,
    required this.onMembershipInfo,
    this.affiliateAgents = const [],
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.isLoadingDependents = false,
    this.dependentsError,
    this.onRetryDependents,
  });

  final List<ClientMembership> memberships;
  final List<ClientDependent> dependents;
  final List<ClientAffiliateAgent> affiliateAgents;
  final ValueChanged<ClientMembership> onMembershipInfo;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final bool isLoadingDependents;
  final String? dependentsError;
  final VoidCallback? onRetryDependents;

  @override
  Widget build(BuildContext context) {
    if (isLoading && memberships.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && memberships.isEmpty) {
      return _TabErrorState(message: error, onRetry: onRetry);
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final membershipWidth = math.min(screenWidth * 0.85, 320.0);
    final dependentWidth = math.min(screenWidth * 0.55, 200.0);

    return ListView(
      physics: VcareRefreshScrollView.physics,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        context.mobileShellBottomContentPadding,
      ),
      children: [
        ClientDetailSectionHeading('Memberships'),
        if (memberships.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.shield,
            title: 'No memberships on file',
            description: 'Membership plans for this client will appear here.',
          )
        else
          ClientDetailCarousel(
            height: 156,
            itemWidth: membershipWidth,
            itemCount: memberships.length,
            itemBuilder: (context, index) {
              final m = memberships[index];
              return ClientMembershipCard(
                membership: m,
                onInfo: () => onMembershipInfo(m),
              );
            },
          ),
        if (affiliateAgents.isNotEmpty) ...[
          const SizedBox(height: 24),
          // const ClientDetailSectionHeading('Affiliates'),
          for (var i = 0; i < affiliateAgents.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            ClientAffiliateCard(agent: affiliateAgents[i]),
          ],
        ],
        const SizedBox(height: 24),
        ClientDetailSectionHeading('Dependents'),
        if (isLoadingDependents && dependents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (dependentsError != null && dependents.isEmpty)
          _TabErrorState(message: dependentsError, onRetry: onRetryDependents)
        else if (dependents.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.users,
            title: 'No dependents on file',
            description:
                'Dependents linked to this client\'s account will appear here.',
          )
        else
          ClientDetailCarousel(
            height: 168,
            itemWidth: dependentWidth,
            itemCount: dependents.length,
            itemBuilder: (context, index) {
              return ClientDependentCard(dependent: dependents[index]);
            },
          ),
      ],
    );
  }
}

class ClientAffiliateCard extends StatelessWidget {
  const ClientAffiliateCard({super.key, required this.agent});

  final ClientAffiliateAgent agent;

  @override
  Widget build(BuildContext context) {
    return ClientContactCard(
      name: agent.name,
      subtitle: agent.email ?? agent.roleLabel,
      avatarUrl: agent.avatarUrl,
      phone: agent.phone,
      email: agent.email,
    );
  }
}

class ClientBillingTab extends ConsumerStatefulWidget {
  const ClientBillingTab({
    super.key,
    required this.clientId,
    required this.memberships,
    required this.paymentMethods,
    required this.transactionsState,
    required this.onTransactionTap,
    this.isLoadingPaymentMethods = false,
    this.paymentMethodsError,
    this.onRetryPaymentMethods,
    this.onRetryTransactions,
    this.onLoadMoreTransactions,
  });

  final String clientId;
  final List<ClientMembership> memberships;
  final List<ClientPaymentMethod> paymentMethods;
  final LoadableListState<ClientTransaction> transactionsState;
  final ValueChanged<ClientTransaction> onTransactionTap;
  final bool isLoadingPaymentMethods;
  final String? paymentMethodsError;
  final VoidCallback? onRetryPaymentMethods;
  final VoidCallback? onRetryTransactions;
  final Future<void> Function()? onLoadMoreTransactions;

  @override
  ConsumerState<ClientBillingTab> createState() => _ClientBillingTabState();
}

class _ClientBillingTabState extends ConsumerState<ClientBillingTab> {
  final _scrollController = ScrollController();
  bool _isLoadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = widget.transactionsState;
    final shouldLoadMore =
        widget.onLoadMoreTransactions != null &&
        state.hasMore &&
        state.items.isNotEmpty &&
        !state.isLoadingMore &&
        state.loadMoreErrorMessage == null &&
        !_isLoadMoreRequested &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= 240;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      widget.onLoadMoreTransactions!.call().whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  Future<void> _setPrimary(ClientPaymentMethod method) async {
    await ref
        .read(clientPaymentMethodsStateProvider(widget.clientId).notifier)
        .setPrimary(
          paymentMethodId: method.id,
          onCompleted: (success, error) {
            if (!mounted) return;
            if (success) {
              context.showVcareToast(
                title: 'Primary updated',
                variant: VcareToastVariant.success,
              );
              return;
            }
            context.showVcareToast(
              title: error ?? 'Could not update primary',
              variant: VcareToastVariant.destructive,
            );
          },
        );
  }

  Future<void> _confirmDelete(ClientPaymentMethod method) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeletePaymentMethodDialog(
        methodLabel: method.label,
        onDelete: () async {
          var didSucceed = false;
          String? errorMessage;

          await ref
              .read(clientPaymentMethodsStateProvider(widget.clientId).notifier)
              .remove(
                paymentMethodId: method.id,
                onCompleted: (success, error) {
                  didSucceed = success;
                  errorMessage = error;
                },
              );

          if (!didSucceed) {
            throw errorMessage ?? 'Remove failed';
          }
        },
      ),
    );

    if (!mounted || deleted != true) return;

    context.showVcareToast(
      title: 'Payment method removed',
      variant: VcareToastVariant.destructive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = widget.memberships
        .where((m) => m.nextBillingDate != null && m.nextBillingDate != '—')
        .toList();
    final transactions = widget.transactionsState.items;

    return ListView(
      controller: _scrollController,
      physics: VcareRefreshScrollView.physics,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        context.mobileShellBottomContentPadding,
      ),
      children: [
        if (upcoming.isNotEmpty) ...[
          ClientUpcomingBillingCard(memberships: upcoming),
          const SizedBox(height: 24),
        ],
        ClientDetailSectionHeading(
          'Payment Methods',
          bottomMargin: 12,
          trailing: TextButton.icon(
            onPressed: () => ClientAddPaymentMethodSheet.show(
              context,
              clientId: widget.clientId,
            ),
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('Add'),
            style: TextButton.styleFrom(
              foregroundColor: context.vcare.primary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (widget.isLoadingPaymentMethods && widget.paymentMethods.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.paymentMethodsError != null &&
            widget.paymentMethods.isEmpty)
          _TabErrorState(
            message: widget.paymentMethodsError,
            onRetry: widget.onRetryPaymentMethods,
          )
        else if (widget.paymentMethods.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.creditCard,
            title: 'No payment methods on file',
            description:
                'Saved cards and bank accounts for billing will appear here.',
          )
        else
          for (var i = 0; i < widget.paymentMethods.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            ClientPaymentMethodCard(
              method: widget.paymentMethods[i],
              onSetPrimary: widget.paymentMethods[i].isPrimary
                  ? null
                  : () => _setPrimary(widget.paymentMethods[i]),
              onDelete: () => _confirmDelete(widget.paymentMethods[i]),
            ),
          ],
        const SizedBox(height: 24),
        const ClientDetailSectionHeading('Transactions'),
        if (widget.transactionsState.isInitialLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.transactionsState.isInitialError)
          _TabErrorState(
            message: widget.transactionsState.operation.errorMessage,
            onRetry: widget.onRetryTransactions,
          )
        else if (transactions.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.receipt,
            title: 'No transactions on file',
            description:
                'Billing history for this client will appear here once charges are recorded.',
          )
        else
          for (var i = 0; i < transactions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            ClientTransactionRow(
              transaction: transactions[i],
              onTap: () => widget.onTransactionTap(transactions[i]),
            ),
          ],
        if (widget.transactionsState.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _DeletePaymentMethodDialog extends StatefulWidget {
  const _DeletePaymentMethodDialog({
    required this.methodLabel,
    required this.onDelete,
  });

  final String methodLabel;
  final Future<void> Function() onDelete;

  @override
  State<_DeletePaymentMethodDialog> createState() =>
      _DeletePaymentMethodDialogState();
}

class _DeletePaymentMethodDialogState
    extends State<_DeletePaymentMethodDialog> {
  var _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      await widget.onDelete();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      final message = error is String ? error : 'Remove failed';
      context.showVcareToast(
        title: message,
        variant: VcareToastVariant.destructive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remove payment method?'),
      content: Text('${widget.methodLabel} will be removed from this client.'),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _handleDelete,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.red.withValues(alpha: 0.7),
            disabledForegroundColor: Colors.white,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}

class ClientCasesTab extends StatefulWidget {
  const ClientCasesTab({
    super.key,
    required this.clientId,
    required this.casesState,
    this.onRetry,
    this.onLoadMore,
  });

  final String clientId;

  final LoadableListState<ClientCase> casesState;
  final VoidCallback? onRetry;
  final Future<void> Function()? onLoadMore;

  @override
  State<ClientCasesTab> createState() => _ClientCasesTabState();
}

class _ClientCasesTabState extends State<ClientCasesTab> {
  final _scrollController = ScrollController();
  bool _isLoadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = widget.casesState;
    final shouldLoadMore =
        widget.onLoadMore != null &&
        state.hasMore &&
        state.items.isNotEmpty &&
        !state.isLoadingMore &&
        state.loadMoreErrorMessage == null &&
        !_isLoadMoreRequested &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= 240;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      widget.onLoadMore!.call().whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cases = widget.casesState.items;

    return ListView(
      controller: _scrollController,
      physics: VcareRefreshScrollView.physics,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        context.mobileShellBottomContentPadding,
      ),
      children: [
        ClientDetailSectionHeading(
          'Cases',
          trailing: TextButton.icon(
            onPressed: () =>
                ClientCreateCaseSheet.show(context, clientId: widget.clientId),
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('New request'),
            style: TextButton.styleFrom(
              foregroundColor: context.vcare.primary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (widget.casesState.isInitialLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.casesState.isInitialError)
          _TabErrorState(
            message: widget.casesState.operation.errorMessage,
            onRetry: widget.onRetry,
          )
        else if (cases.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.inbox,
            title: 'No cases for this client',
            description:
                'Requests and cases opened for this client will show up here.',
          )
        else
          for (var i = 0; i < cases.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            ClientCaseCard(clientCase: cases[i]),
          ],
        if (widget.casesState.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class ClientDocumentsTab extends StatefulWidget {
  const ClientDocumentsTab({
    super.key,
    required this.clientId,
    required this.documentsState,
    this.onRetry,
    this.onLoadMore,
    this.onDocumentAction,
  });

  final String clientId;

  final ClientDocumentsLoadableState documentsState;
  final VoidCallback? onRetry;
  final Future<void> Function()? onLoadMore;
  final void Function(ClientFile file, String action)? onDocumentAction;

  @override
  State<ClientDocumentsTab> createState() => _ClientDocumentsTabState();
}

class _ClientDocumentsTabState extends State<ClientDocumentsTab> {
  final _scrollController = ScrollController();
  bool _isLoadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = widget.documentsState;
    final shouldLoadMore =
        widget.onLoadMore != null &&
        state.hasMore &&
        state.items.isNotEmpty &&
        !state.isLoadingMore &&
        state.loadMoreErrorMessage == null &&
        !_isLoadMoreRequested &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= 240;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      widget.onLoadMore!.call().whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.documentsState.items;

    return ListView(
      controller: _scrollController,
      physics: VcareRefreshScrollView.physics,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        context.mobileShellBottomContentPadding,
      ),
      children: [
        ClientDetailSectionHeading(
          'Documents',
          trailing: TextButton.icon(
            onPressed: widget.documentsState.isUploading
                ? null
                : () => ClientUploadDocumentSheet.show(
                    context,
                    clientId: widget.clientId,
                  ),
            icon: const Icon(LucideIcons.upload, size: 14),
            label: const Text('Upload'),
            style: TextButton.styleFrom(
              foregroundColor: context.vcare.primary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (widget.documentsState.isUploading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Uploading document...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.vcare.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (widget.documentsState.isInitialLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.documentsState.isInitialError)
          _TabErrorState(
            message: widget.documentsState.operation.errorMessage,
            onRetry: widget.onRetry,
          )
        else if (files.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.paperclip,
            title: 'No documents uploaded',
            description:
                'ID cards, bills, and other client files will appear here.',
          )
        else
          for (var i = 0; i < files.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            ClientDocumentRow(
              file: files[i],
              onAction: widget.onDocumentAction == null
                  ? null
                  : (action) => widget.onDocumentAction!(files[i], action),
            ),
          ],
        if (widget.documentsState.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class ClientUpcomingBillingCard extends StatelessWidget {
  const ClientUpcomingBillingCard({super.key, required this.memberships});

  final List<ClientMembership> memberships;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.vcare.primary.withValues(alpha: 0.05),
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: context.vcare.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: context.vcare.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.calendarClock,
                    size: 14,
                    color: context.vcare.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'UPCOMING BILLING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: context.vcare.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final m in memberships)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.vcare.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 12, height: 1.4),
                          children: [
                            const TextSpan(text: 'Next billing on '),
                            TextSpan(
                              text: formatClientDateNumeric(m.nextBillingDate!),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' — '),
                            TextSpan(
                              text: '\$${m.cost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' for '),
                            TextSpan(
                              text: m.plan,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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

class ClientMembershipCard extends StatelessWidget {
  const ClientMembershipCard({
    super.key,
    required this.membership,
    required this.onInfo,
  });

  final ClientMembership membership;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final showInfo =
        membership.status == ClientMembershipStatus.completed ||
        membership.status == ClientMembershipStatus.cancelled;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        membership.plan,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        membership.tier,
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                ClientStatusChip.membership(membership.status),
                if (showInfo) ...[
                  const SizedBox(width: 6),
                  _MembershipInfoButton(onPressed: onInfo),
                ],
              ],
            ),
            Divider(color: vcare.border, height: 25),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatClientDateNumeric(membership.benefitDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Benefit Date',
                        style: TextStyle(
                          fontSize: 11,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${membership.cost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      membership.costUnit,
                      style: TextStyle(
                        fontSize: 11,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipInfoButton extends StatelessWidget {
  const _MembershipInfoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.muted,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(LucideIcons.info, size: 14, color: vcare.mutedForeground),
        ),
      ),
    );
  }
}

class ClientDependentCard extends StatelessWidget {
  const ClientDependentCard({super.key, required this.dependent});

  final ClientDependent dependent;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: SizedBox(
                width: 64,
                height: 64,
                child: VCareCachedImage(
                  imageUrl: dependent.avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: ColoredBox(
                    color: vcare.muted,
                    child: Center(
                      child: Text(
                        clientInitials(dependent.name),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dependent.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              dependent.relation,
              style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ClientPaymentMethodCard extends StatelessWidget {
  const ClientPaymentMethodCard({
    super.key,
    required this.method,
    this.onSetPrimary,
    this.onDelete,
  });

  final ClientPaymentMethod method;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onDelete;

  IconData _iconForType() {
    switch (method.type) {
      case ClientPaymentMethodType.creditDebitCard:
        return LucideIcons.creditCard;
      case ClientPaymentMethodType.bankTransfer:
        return LucideIcons.landmark;
      case ClientPaymentMethodType.cash:
        return LucideIcons.banknote;
      case ClientPaymentMethodType.check:
        return LucideIcons.receipt;
      case ClientPaymentMethodType.others:
        return LucideIcons.helpCircle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.vcare.primary.withValues(alpha: 0.1),
                borderRadius: VCareRadius.lgAll,
              ),
              child: Icon(_iconForType(), size: 16, color: context.vcare.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    clientPaymentMethodTypeLabel(method.type),
                    style: TextStyle(
                      fontSize: 11,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (method.isPrimary)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      size: 12,
                      color: context.vcare.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Primary',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.vcare.primary,
                      ),
                    ),
                  ],
                ),
              ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(
                LucideIcons.moreVertical,
                size: 16,
                color: vcare.mutedForeground,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: VCareRadius.lgAll,
              ),
              onSelected: (value) {
                if (value == 'primary') {
                  onSetPrimary?.call();
                } else if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                if (!method.isPrimary)
                  const PopupMenuItem(
                    value: 'primary',
                    child: Row(
                      children: [
                        Icon(LucideIcons.star, size: 16),
                        SizedBox(width: 8),
                        Text('Set as primary'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
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

class ClientTransactionRow extends StatelessWidget {
  const ClientTransactionRow({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final ClientTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.lgAll,
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.membershipTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatClientDateNumeric(transaction.date),
                      style: TextStyle(
                        fontSize: 10,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClientStatusChip.transaction(transaction.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientCaseCard extends StatelessWidget {
  const ClientCaseCard({super.key, required this.clientCase});

  final ClientCase clientCase;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.vcare.primary.withValues(alpha: 0.1),
                borderRadius: VCareRadius.lgAll,
              ),
              child: Icon(
                LucideIcons.fileText,
                size: 16,
                color: context.vcare.primary,
              ),
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
                          clientCase.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ClientStatusChip.caseStatus(clientCase.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '#${clientCase.caseId}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '•',
                          style: TextStyle(
                            fontSize: 11,
                            color: vcare.mutedForeground.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Text(
                        'Created ${formatClientDateNumeric(clientCase.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
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

class ClientDocumentRow extends StatelessWidget {
  const ClientDocumentRow({super.key, required this.file, this.onAction});

  final ClientFile file;
  final void Function(String action)? onAction;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isImage = file.mime.startsWith('image/') && file.url.isUrl;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: VCareRadius.lgAll,
              child: Container(
                width: 40,
                height: 40,
                color: context.vcare.primary.withValues(alpha: 0.1),
                child: isImage
                    ? VCareCachedImage(
                        imageUrl: file.url,
                        cacheKey: 'client-file:${file.id}',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: Icon(
                          LucideIcons.fileText,
                          size: 16,
                          color: context.vcare.primary,
                        ),
                      )
                    : Icon(
                        LucideIcons.fileText,
                        size: 16,
                        color: context.vcare.primary,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${file.size} · ${formatClientDateNumeric(file.uploadedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: onAction,
              icon: Icon(
                LucideIcons.moreVertical,
                size: 16,
                color: vcare.mutedForeground,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: VCareRadius.lgAll,
              ),
              itemBuilder: (context) => [
                if (isImage)
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(LucideIcons.eye, size: 16),
                        SizedBox(width: 8),
                        Text('Preview'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(LucideIcons.download, size: 16),
                      SizedBox(width: 8),
                      Text('Download'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(LucideIcons.pencil, size: 16),
                      SizedBox(width: 8),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
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

class _TabErrorState extends StatelessWidget {
  const _TabErrorState({required this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return VcareInlineErrorCard(
      message: message,
      onRetry: onRetry,
    );
  }
}
