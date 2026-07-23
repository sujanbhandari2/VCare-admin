import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_history_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_sales_history_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_summary_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_detail_sheet.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_empty_state.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_filters.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_history_row.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_sales_history_row.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_summary_section.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';

class CommissionDetailScreen extends ConsumerStatefulWidget {
  const CommissionDetailScreen({super.key, this.showBack = false});

  final bool showBack;

  @override
  ConsumerState<CommissionDetailScreen> createState() =>
      _CommissionDetailScreenState();
}

class _CommissionDetailScreenState
    extends ConsumerState<CommissionDetailScreen> {
  static const double _loadMoreTriggerThreshold = 240;

  final _scrollController = ScrollController();
  bool _isLoadMoreRequested = false;

  bool _resolveUsesSalesHistory() {
    final id = ref.read(localProfileStateProvider).agencyGroupId?.trim();
    return id != null && id.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial(syncProfile: true);
    });
  }

  Future<void> _loadList({
    required bool usesSalesHistory,
    bool forceRefresh = false,
  }) {
    if (usesSalesHistory) {
      final notifier = ref.read(commissionSalesHistoryStateProvider.notifier);
      return forceRefresh ? notifier.refresh() : notifier.loadInitial();
    }
    final notifier = ref.read(commissionHistoryStateProvider.notifier);
    return forceRefresh ? notifier.refresh() : notifier.loadInitial();
  }

  Future<void> _loadInitial({bool syncProfile = false}) async {
    if (syncProfile) {
      await ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true);
    }
    final usesSalesHistory = _resolveUsesSalesHistory();
    await Future.wait([
      ref.read(commissionSummaryStateProvider.notifier).fetchSummary(),
      _loadList(usesSalesHistory: usesSalesHistory),
    ]);
  }

  Future<void> _onFilterChanged(CommissionFilter value) async {
    final usesSalesHistory = _resolveUsesSalesHistory();
    final futures = <Future<void>>[
      ref.read(commissionSummaryStateProvider.notifier).setFilter(value),
    ];
    if (usesSalesHistory) {
      futures.add(
        ref.read(commissionSalesHistoryStateProvider.notifier).setFilter(value),
      );
    } else {
      futures.add(
        ref.read(commissionHistoryStateProvider.notifier).setFilter(value),
      );
    }
    await Future.wait(futures);
  }

  void _onScroll() {
    final usesSalesHistory = _resolveUsesSalesHistory();
    final hasMore = usesSalesHistory
        ? ref.read(commissionSalesHistoryStateProvider).hasMore
        : ref.read(commissionHistoryStateProvider).hasMore;
    final hasItems = usesSalesHistory
        ? ref.read(commissionSalesHistoryStateProvider).items.isNotEmpty
        : ref.read(commissionHistoryStateProvider).items.isNotEmpty;
    final isLoadingMore = usesSalesHistory
        ? ref.read(commissionSalesHistoryStateProvider).isLoadingMore
        : ref.read(commissionHistoryStateProvider).isLoadingMore;
    final loadMoreError = usesSalesHistory
        ? ref.read(commissionSalesHistoryStateProvider).loadMoreErrorMessage
        : ref.read(commissionHistoryStateProvider).loadMoreErrorMessage;
    final isInitialLoading = usesSalesHistory
        ? ref.read(commissionSalesHistoryStateProvider).isInitialLoading
        : ref.read(commissionHistoryStateProvider).isInitialLoading;
    final isInitialError = usesSalesHistory
        ? ref.read(commissionSalesHistoryStateProvider).isInitialError
        : ref.read(commissionHistoryStateProvider).isInitialError;

    final shouldLoadMore =
        hasMore &&
        hasItems &&
        !isLoadingMore &&
        loadMoreError == null &&
        !isInitialLoading &&
        !isInitialError &&
        !_isLoadMoreRequested &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= _loadMoreTriggerThreshold;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      final loadMore = usesSalesHistory
          ? ref.read(commissionSalesHistoryStateProvider.notifier).loadMore()
          : ref.read(commissionHistoryStateProvider.notifier).loadMore();
      loadMore.whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true);
    final usesSalesHistory = _resolveUsesSalesHistory();
    await Future.wait([
      ref.read(commissionSummaryStateProvider.notifier).fetchSummary(),
      _loadList(usesSalesHistory: usesSalesHistory, forceRefresh: true),
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
    final agencyGroupId = ref
        .watch(localProfileStateProvider)
        .agencyGroupId
        ?.trim();
    final usesSalesHistory = agencyGroupId != null && agencyGroupId.isNotEmpty;

    final commissionHistoryState = ref.watch(commissionHistoryStateProvider);
    final salesHistoryState = ref.watch(commissionSalesHistoryStateProvider);

    final isInitialLoadingList = usesSalesHistory
        ? salesHistoryState.isInitialLoading
        : commissionHistoryState.isInitialLoading;
    final isInitialErrorList = usesSalesHistory
        ? salesHistoryState.isInitialError
        : commissionHistoryState.isInitialError;
    final isEmptyList = usesSalesHistory
        ? salesHistoryState.isEmpty
        : commissionHistoryState.isEmpty;
    final totalItems = usesSalesHistory
        ? salesHistoryState.totalItems
        : commissionHistoryState.totalItems;
    final isLoadingMore = usesSalesHistory
        ? salesHistoryState.isLoadingMore
        : commissionHistoryState.isLoadingMore;
    final loadMoreErrorMessage = usesSalesHistory
        ? salesHistoryState.loadMoreErrorMessage
        : commissionHistoryState.loadMoreErrorMessage;
    final listErrorMessage = usesSalesHistory
        ? salesHistoryState.operation.errorMessage
        : commissionHistoryState.operation.errorMessage;
    final historyFilter = usesSalesHistory
        ? ref.watch(commissionSalesHistoryStateProvider.notifier).filter
        : ref.watch(commissionHistoryStateProvider.notifier).filter;

    final summary = summaryState.data;
    final isAgencyGroup = summary?.isAgencyGroup ?? false;
    final vcare = context.vcare;

    final isInitialLoading =
        (summaryState.fetching && summary == null) || isInitialLoadingList;

    final showEmptyState =
        !isInitialLoading &&
        !isInitialErrorList &&
        summaryState.error == null &&
        historyFilter == CommissionFilter.all &&
        isCommissionSummaryEmpty(
          totalSales: summary?.totalSales,
          historyEmpty: isEmptyList,
        );

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
                showBack: widget.showBack,
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
                      Expanded(
                        child: Text(
                          usesSalesHistory
                              ? 'Total Sales'
                              : 'Commission History',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '$totalItems entries',
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CommissionFilters(
                    value: historyFilter,
                    onChanged: _onFilterChanged,
                  ),
                  const SizedBox(height: 12),
                  if (isInitialLoadingList)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (isInitialErrorList)
                    VcareInlineErrorCard(
                      message: listErrorMessage,
                      onRetry: () =>
                          _loadList(usesSalesHistory: usesSalesHistory),
                    )
                  else if (isEmptyList)
                    usesSalesHistory
                        ? const CommissionSalesHistoryEmptyFilter()
                        : const CommissionHistoryEmptyFilter()
                  else ...[
                    if (usesSalesHistory)
                      ...salesHistoryState.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CommissionSalesHistoryRow(item: item),
                        ),
                      )
                    else
                      ...commissionHistoryState.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CommissionHistoryRow(
                            item: item,
                            onTap: () =>
                                showCommissionDetailSheet(context, item),
                          ),
                        ),
                      ),
                    if (isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (loadMoreErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton(
                          onPressed: () {
                            if (usesSalesHistory) {
                              ref
                                  .read(
                                    commissionSalesHistoryStateProvider
                                        .notifier,
                                  )
                                  .loadMore();
                            } else {
                              ref
                                  .read(commissionHistoryStateProvider.notifier)
                                  .loadMore();
                            }
                          },
                          child: Text(
                            NetworkErrorMessage.displayMessage(
                              context,
                              message: loadMoreErrorMessage,
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
