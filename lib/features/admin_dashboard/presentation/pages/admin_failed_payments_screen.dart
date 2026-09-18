import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_failed_payments_list_state_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_empty_states.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_failed_payment_row.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_failed_payment_mapper.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_transaction_detail_sheet.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';

class AdminFailedPaymentsScreen extends ConsumerStatefulWidget {
  const AdminFailedPaymentsScreen({super.key});

  @override
  ConsumerState<AdminFailedPaymentsScreen> createState() =>
      _AdminFailedPaymentsScreenState();
}

class _AdminFailedPaymentsScreenState
    extends ConsumerState<AdminFailedPaymentsScreen> {
  static const double _loadMoreTriggerThreshold = 240;

  final _scrollController = ScrollController();
  bool _isLoadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(adminFailedPaymentsListStateProvider);
      if (state.isInitialLoading || state.isRefreshing) return;

      final notifier = ref.read(adminFailedPaymentsListStateProvider.notifier);
      if (state.items.isEmpty) {
        if (!state.isInitialError) notifier.loadInitial();
        return;
      }

      // The list is kept alive, so re-entering the screen revalidates the
      // cached page instead of showing whatever was loaded last time.
      notifier.refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final listState = ref.read(adminFailedPaymentsListStateProvider);
    final shouldLoadMore =
        listState.hasMore &&
        listState.items.isNotEmpty &&
        !listState.isLoadingMore &&
        listState.loadMoreErrorMessage == null &&
        !listState.isInitialLoading &&
        !listState.isInitialError &&
        !_isLoadMoreRequested &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= _loadMoreTriggerThreshold;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      ref
          .read(adminFailedPaymentsListStateProvider.notifier)
          .loadMore()
          .whenComplete(() {
            if (mounted) {
              _isLoadMoreRequested = false;
            }
          });
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(adminFailedPaymentsListStateProvider.notifier).sync();
  }

  Future<void> _openRecovery(AdminDashboardFailedPaymentTodoItem item) async {
    final payerId = item.details.relatedId?.trim() ?? '';
    final transactionId = item.resource.id.trim();
    if (payerId.isEmpty || transactionId.isEmpty) return;

    final recovered = await TodoTransactionDetailSheet.show(
      context,
      item: item.toTodoItem(),
    );
    if (recovered != true || !mounted) return;
    await _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(adminFailedPaymentsListStateProvider);
    final items = listState.items;

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        controller: _scrollController,
        slivers: [
          const SliverVcarePageHeader(title: 'Failed Payments', showBack: true),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: listState.isInitialLoading && items.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : listState.isInitialError && items.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: VcareErrorStatePanel(
                      title: 'Unable to load failed payments',
                      message: listState.operation.errorMessage,
                      actionLabel: 'Try again',
                      onAction: () => ref
                          .read(adminFailedPaymentsListStateProvider.notifier)
                          .loadInitial(),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate([
                      if (items.isEmpty)
                        const AdminDashboardFailedPaymentsEmptyState()
                      else ...[
                        for (var i = 0; i < items.length; i++) ...[
                          AdminDashboardFailedPaymentRow(
                            item: items[i],
                            onTap: () => _openRecovery(items[i]),
                          ),
                          if (i < items.length - 1) const SizedBox(height: 8),
                        ],
                        if (listState.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                    ]),
                  ),
          ),
        ],
      ),
    );
  }
}
