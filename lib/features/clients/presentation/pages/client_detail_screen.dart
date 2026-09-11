import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/features/clients/presentation/pages/client_case_create_screen.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_cases_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_dependents_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_detail_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_documents_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_memberships_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_payment_methods_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_transactions_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_contact_card.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_detail_tab_bar.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_detail_tabs.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_details_drawer.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_document_preview_dialog.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_transaction_detail_sheet.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Client detail — parity with vcareapp [ClientDetailPage].
class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({
    super.key,
    required this.clientId,
    this.clientType = ClientListType.individual,
  });

  final String clientId;
  final ClientListType clientType;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, String> _txnNotes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Always refetch when this screen is opened (providers are keepAlive).
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRefresh());
  }

  Future<void> _onRefresh() async {
    final clientId = widget.clientId;
    await Future.wait([
      ref
          .read(clientDetailStateProvider(clientId).notifier)
          .fetchDetail(clientType: widget.clientType),
      ref
          .read(clientMembershipsStateProvider(clientId).notifier)
          .fetchMemberships(),
      ref.read(clientDependentsStateProvider(clientId).notifier).fetchDependents(),
      ref
          .read(clientPaymentMethodsStateProvider(clientId).notifier)
          .fetchPaymentMethods(),
      ref.read(clientTransactionsStateProvider(clientId).notifier).refresh(),
      ref.read(clientCasesStateProvider(clientId).notifier).refresh(),
      ref.read(clientDocumentsStateProvider(clientId).notifier).refresh(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientId = widget.clientId;
    final detailState = ref.watch(clientDetailStateProvider(clientId));
    final membershipsState = ref.watch(
      clientMembershipsStateProvider(clientId),
    );
    final dependentsState = ref.watch(clientDependentsStateProvider(clientId));
    final paymentMethodsState = ref.watch(
      clientPaymentMethodsStateProvider(clientId),
    );
    final transactionsState = ref.watch(
      clientTransactionsStateProvider(clientId),
    );
    final casesState = ref.watch(clientCasesStateProvider(clientId));
    final documentsState = ref.watch(clientDocumentsStateProvider(clientId));

    final detail = detailState.data;
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    final vcare = context.vcare;

    if (detailState.fetching && detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (detail == null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: VcarePinnedPageTitleDelegate(
                safeTop: safeTop,
                textScaleFactor: textScaleFactor,
                hasSubtitle: false,
                title: vcareTabPageTitle(
                  title: 'Client not found',
                  showBack: true,
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: VcareErrorStatePanel(
                title: 'Client not found',
                message: detailState.error,
                actionLabel: 'Back to clients',
                onAction: () => context.pop(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        // NestedScrollView + TabBarView nest scrollables, so default
        // depth == 0 misses pulls on tab ListViews. Accept any vertical
        // scroll notification so pull-to-refresh works from every tab.
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.vertical,
        child: NestedScrollView(
          physics: VcareRefreshScrollView.physics,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverPersistentHeader(
              pinned: true,
              delegate: VcarePinnedPageTitleDelegate(
                safeTop: safeTop,
                textScaleFactor: textScaleFactor,
                hasSubtitle: false,
                title: vcareTabPageTitle(
                  title: detail.fullName,
                  showBack: true,
                  action: IconButton(
                    onPressed: () => ClientDetailsDrawer.show(context, detail),
                    icon: const Icon(LucideIcons.info, size: 16),
                    tooltip: 'Client details',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      maximumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                      foregroundColor: vcare.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _IdentityCard(detail: detail)),
            SliverPersistentHeader(
              pinned: true,
              delegate: ClientDetailTabBarHeader(
                tabBar: ClientDetailTabBar(controller: _tabController),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              ClientMembershipsTab(
                memberships: membershipsState.data?.memberships ?? const [],
                dependents: dependentsState.dependents,
                affiliateAgents: detail.affiliateAgents,
                isLoading: membershipsState.fetching,
                error: membershipsState.error,
                isLoadingDependents: dependentsState.fetching,
                dependentsError: dependentsState.error,
                onRetry: () => ref
                    .read(clientMembershipsStateProvider(clientId).notifier)
                    .fetchMemberships(),
                onRetryDependents: () => ref
                    .read(clientDependentsStateProvider(clientId).notifier)
                    .fetchDependents(),
                onMembershipInfo: (m) => _showMembershipNote(context, m),
              ),
              ClientBillingTab(
                clientId: clientId,
                memberships: membershipsState.data?.memberships ?? const [],
                paymentMethods: paymentMethodsState.methods,
                transactionsState: transactionsState,
                isLoadingPaymentMethods: paymentMethodsState.fetching,
                paymentMethodsError: paymentMethodsState.error,
                onRetryPaymentMethods: () => ref
                    .read(clientPaymentMethodsStateProvider(clientId).notifier)
                    .fetchPaymentMethods(),
                onRetryTransactions: () => ref
                    .read(clientTransactionsStateProvider(clientId).notifier)
                    .loadInitial(),
                onLoadMoreTransactions: () => ref
                    .read(clientTransactionsStateProvider(clientId).notifier)
                    .loadMore(),
                onTransactionTap: (t) => _showTransactionDetails(
                  context,
                  transaction: t,
                  clientName: detail.fullName,
                  clientEmail: detail.email,
                  dependents: dependentsState.dependents,
                ),
              ),
              ClientCasesTab(
                clientId: clientId,
                casesState: casesState,
                onRetry: () => ref
                    .read(clientCasesStateProvider(clientId).notifier)
                    .loadInitial(),
                onLoadMore: () => ref
                    .read(clientCasesStateProvider(clientId).notifier)
                    .loadMore(),
                onCreateCase: () {
                  context.pushNamed(
                    AppRouter.clientCaseCreateName,
                    pathParameters: {'id': clientId},
                    extra: caseCreationClientFromDetail(detail),
                  );
                },
              ),
              ClientDocumentsTab(
                clientId: clientId,
                documentsState: documentsState,
                onRetry: () => ref
                    .read(clientDocumentsStateProvider(clientId).notifier)
                    .loadInitial(),
                onLoadMore: () => ref
                    .read(clientDocumentsStateProvider(clientId).notifier)
                    .loadMore(),
                onDocumentAction: (file, action) =>
                    _handleDocumentAction(context, clientId, file, action),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context, {
    required ClientTransaction transaction,
    required String clientName,
    required String clientEmail,
    required List<ClientDependent> dependents,
  }) {
    ClientTransactionDetailSheet.show(
      context,
      clientId: widget.clientId,
      transaction: transaction,
      clientName: clientName,
      clientEmail: clientEmail,
      dependents: dependents,
      localNote: _txnNotes[transaction.id],
      onNoteSaved: (note) => _txnNotes[transaction.id] = note,
    );
  }

  void _showMembershipNote(BuildContext context, ClientMembership membership) {
    context.showBottomSheet<void>(
      builder: (sheetContext) => _MembershipNoteSheet(
        membership: membership,
        onClose: () => Navigator.pop(sheetContext),
      ),
    );
  }

  Future<void> _handleDocumentAction(
    BuildContext context,
    String clientId,
    ClientFile file,
    String action,
  ) async {
    switch (action) {
      case 'preview':
        await ClientDocumentPreviewDialog.show(context, file);
      case 'download':
        await _downloadDocument(context, file);
      case 'rename':
        await _renameDocument(context, clientId, file);
      case 'delete':
        await _deleteDocument(context, clientId, file);
    }
  }

  Future<void> _downloadDocument(BuildContext context, ClientFile file) async {
    final url = file.viewUrl;

    if (url.startsWith('data:')) {
      if (!context.mounted) return;
      context.showVcareToast(
        title: 'File saved locally on this device.',
        variant: VcareToastVariant.success,
      );
      return;
    }

    final launched = url.isUrl
        ? await launchUrlString(url, mode: LaunchMode.externalApplication)
        : false;
    if (!context.mounted) return;
    if (!launched) {
      context.showVcareToast(
        title: 'Could not open ${file.name}.',
        variant: VcareToastVariant.destructive,
      );
    }
  }

  Future<void> _renameDocument(
    BuildContext context,
    String clientId,
    ClientFile file,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDocumentDialog(initialName: file.name),
    );

    final trimmed = newName?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == file.name) return;
    if (!context.mounted) return;

    final result = await ref
        .read(clientDocumentsStateProvider(clientId).notifier)
        .renameDocument(documentId: file.id, name: trimmed);

    if (!context.mounted) return;

    if (result.success) {
      context.showVcareToast(
        title: 'Renamed',
        description: trimmed,
        variant: VcareToastVariant.info,
      );
    } else {
      context.showVcareToast(
        title: 'Could not rename document',
        description: result.error,
        variant: VcareToastVariant.destructive,
      );
    }
  }

  Future<void> _deleteDocument(
    BuildContext context,
    String clientId,
    ClientFile file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          '${file.name} will be permanently removed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref
        .read(clientDocumentsStateProvider(clientId).notifier)
        .deleteDocument(documentId: file.id);

    if (!context.mounted) return;

    if (result.success) {
      context.showVcareToast(
        title: 'Document deleted',
        description: file.name,
        variant: VcareToastVariant.info,
      );
    } else {
      context.showVcareToast(
        title: 'Could not delete document',
        description: result.error,
        variant: VcareToastVariant.destructive,
      );
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.detail});

  final ClientDetail detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ClientContactCard(
        label: 'CLIENT',
        name: detail.fullName,
        subtitle: detail.email,
        avatarUrl: detail.avatarUrl,
        phone: detail.phone,
        email: detail.email,
      ),
    );
  }
}

class _MembershipNoteSheet extends StatelessWidget {
  const _MembershipNoteSheet({required this.membership, required this.onClose});

  final ClientMembership membership;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Note Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
                ],
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: vcare.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    membership.note ?? 'No notes for this membership.',
                    style: const TextStyle(fontSize: 14, height: 1.4),
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

class _RenameDocumentDialog extends StatefulWidget {
  const _RenameDocumentDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDocumentDialog> createState() => _RenameDocumentDialogState();
}

class _RenameDocumentDialogState extends State<_RenameDocumentDialog> {
  late final TextEditingController _controller;
  late final String _extension;

  @override
  void initState() {
    super.initState();
    final parts = splitDocumentFileName(widget.initialName);
    _extension = parts.extension;
    _controller = TextEditingController(text: parts.baseName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final baseName = _controller.text.trim();
    if (baseName.isEmpty) return;

    Navigator.pop(
      context,
      joinDocumentFileName(baseName: baseName, extension: _extension),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return AlertDialog(
      title: const Text('Rename document'),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Document name'),
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (_extension.isNotEmpty) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _extension,
                style: TextStyle(
                  fontSize: 16,
                  color: vcare.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
