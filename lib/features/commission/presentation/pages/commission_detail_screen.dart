import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_history_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_summary_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_detail_sheet.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_empty_state.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_filters.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_history_row.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_summary_section.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';

class CommissionDetailScreen extends ConsumerStatefulWidget {
  const CommissionDetailScreen({super.key});

  @override
  ConsumerState<CommissionDetailScreen> createState() =>
      _CommissionDetailScreenState();
}

class _CommissionDetailScreenState extends ConsumerState<CommissionDetailScreen> {
  static const double _loadMoreTriggerThreshold = 240;

  final _scrollController = ScrollController();
  bool _isLoadMoreRequested = false;
  CommissionFilter _filter = CommissionFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commissionSummaryStateProvider.notifier).fetchSummary();
      ref.read(commissionHistoryStateProvider.notifier).loadInitial();
    });
  }

  void _onScroll() {
    final listState = ref.read(commissionHistoryStateProvider);
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
      ref.read(commissionHistoryStateProvider.notifier).loadMore().whenComplete(
        () {
          if (mounted) {
            _isLoadMoreRequested = false;
          }
        },
      );
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(commissionSummaryStateProvider.notifier).fetchSummary(),
      ref.read(commissionHistoryStateProvider.notifier).refresh(),
    ]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(commissionSummaryStateProvider);
    final historyState = ref.watch(commissionHistoryStateProvider);
    final summary = summaryState.data;
    final isAgencyGroup = summary?.isAgencyGroup ?? false;
    final vcare = context.vcare;

    final isInitialLoading =
        (summaryState.fetching && summary == null) || historyState.isInitialLoading;

    final showEmptyState = !isInitialLoading &&
        !historyState.isInitialError &&
        summaryState.error == null &&
        isCommissionSummaryEmpty(
          totalSales: summary?.totalSales,
          historyEmpty: historyState.isEmpty,
        );

    final filteredItems = filterCommissionHistory(historyState.items, _filter);
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: VcareRefreshScrollView(
        controller: _scrollController,
        onRefresh: _onRefresh,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              textScaleFactor: textScaleFactor,
              hasSubtitle: false,
              title: vcareTabPageTitle(
                title: 'My Commissions',
                showBack: true,
              ),
            ),
          ),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (showEmptyState)
                  const CommissionEmptyState()
                else ...[
                  CommissionSummarySection(
                    summary: summary,
                    isLoading: summaryState.fetching && summary == null,
                    isAgencyGroup: isAgencyGroup,
                    error: summary == null ? summaryState.error : null,
                    onRetry: () => ref
                        .read(commissionSummaryStateProvider.notifier)
                        .fetchSummary(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Commission History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${filteredItems.length} entries',
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CommissionFilters(
                    value: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                  const SizedBox(height: 12),
                  if (historyState.isInitialLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (historyState.isInitialError)
                    VcareInlineErrorCard(
                      message: historyState.operation.errorMessage,
                      onRetry: () => ref
                          .read(commissionHistoryStateProvider.notifier)
                          .loadInitial(),
                    )
                  else if (filteredItems.isEmpty)
                    const CommissionHistoryEmptyFilter()
                  else ...[
                    ...filteredItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CommissionHistoryRow(
                          item: item,
                          maskAmount: isAgencyGroup,
                          onTap: isAgencyGroup
                              ? null
                              : () => showCommissionDetailSheet(context, item),
                        ),
                      ),
                    ),
                    if (historyState.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (historyState.loadMoreErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton(
                          onPressed: () => ref
                              .read(commissionHistoryStateProvider.notifier)
                              .loadMore(),
                          child: Text(
                            NetworkErrorMessage.displayMessage(
                              context,
                              message: historyState.loadMoreErrorMessage,
                            ),
                            style: TextStyle(color: vcare.mutedForeground),
                          ),
                        ),
                      ),
                  ],
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.message,
    this.onRetry,
    this.muted = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            NetworkErrorMessage.displayMessage(context, message: message),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: muted ? vcare.mutedForeground : null,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(context.appLocalization.retry),
            ),
          ],
        ],
      ),
    );
  }
}
