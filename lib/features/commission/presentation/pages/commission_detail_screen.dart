import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_history_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_sales_history_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_summary_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_empty_state.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_history_list.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_history_row.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_pager.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_sales_history_row.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_summary_section.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
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
  /// Match web CommissionDetail: stats.isAgencyAssociated || profile.agencyGroup
  /// (plus summary null-commission as a fallback).
  bool _resolveUsesSalesHistory({bool? summaryIsAgency}) {
    final statsAgency =
        ref.read(agentStatsStateProvider).data?.isAgencyAssociated ?? false;
    if (statsAgency) return true;
    final profile = ref.read(localProfileStateProvider);
    if (profile.hasAgencyGroup) return true;
    return summaryIsAgency ?? false;
  }

  String _entryCountLabel(int count) {
    return count == 1 ? '1 entry' : '$count entries';
  }

  @override
  void initState() {
    super.initState();
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
    await ref.read(commissionSummaryStateProvider.notifier).fetchSummary();
    if (!mounted) return;
    final summaryIsAgency =
        ref.read(commissionSummaryStateProvider).data?.isAgencyGroup ?? false;
    final usesSalesHistory = _resolveUsesSalesHistory(
      summaryIsAgency: summaryIsAgency,
    );
    await _loadList(usesSalesHistory: usesSalesHistory);
  }

  Future<void> _onRefresh() async {
    await ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true);
    await ref.read(commissionSummaryStateProvider.notifier).fetchSummary();
    if (!mounted) return;
    final summaryIsAgency =
        ref.read(commissionSummaryStateProvider).data?.isAgencyGroup ?? false;
    final usesSalesHistory = _resolveUsesSalesHistory(
      summaryIsAgency: summaryIsAgency,
    );
    await _loadList(usesSalesHistory: usesSalesHistory, forceRefresh: true);
  }

  Future<void> _onPageChange(int page, {required bool usesSalesHistory}) {
    if (usesSalesHistory) {
      return ref
          .read(commissionSalesHistoryStateProvider.notifier)
          .loadPage(page);
    }
    return ref.read(commissionHistoryStateProvider.notifier).loadPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(commissionSummaryStateProvider);
    final profile = ref.watch(localProfileStateProvider);
    final statsAgency =
        ref.watch(agentStatsStateProvider).data?.isAgencyAssociated ?? false;
    final summary = summaryState.data;
    final isAgencyGroup = summary?.isAgencyGroup ?? false;
    final usesSalesHistory =
        statsAgency || profile.hasAgencyGroup || isAgencyGroup;

    final commissionHistoryState = ref.watch(commissionHistoryStateProvider);
    final salesHistoryState = ref.watch(commissionSalesHistoryStateProvider);

    final isInitialLoadingList = usesSalesHistory
        ? salesHistoryState.isInitialLoading
        : commissionHistoryState.isInitialLoading;
    final isRefreshingList = usesSalesHistory
        ? salesHistoryState.isRefreshing
        : commissionHistoryState.isRefreshing;
    final isInitialErrorList = usesSalesHistory
        ? salesHistoryState.isInitialError
        : commissionHistoryState.isInitialError;
    final isEmptyList = usesSalesHistory
        ? salesHistoryState.isEmpty
        : commissionHistoryState.isEmpty;
    final totalItems = usesSalesHistory
        ? salesHistoryState.totalItems
        : commissionHistoryState.totalItems;
    final listErrorMessage = usesSalesHistory
        ? salesHistoryState.operation.errorMessage
        : commissionHistoryState.operation.errorMessage;

    final pageSize = PaginatedListNotifierMixin.defaultPageSize;
    final currentPage = usesSalesHistory
        ? ref.read(commissionSalesHistoryStateProvider.notifier).currentPage
        : ref.read(commissionHistoryStateProvider.notifier).currentPage;
    final page = currentPage < 1 ? 1 : currentPage;
    final totalPages = totalItems == 0
        ? 1
        : ((totalItems + pageSize - 1) / pageSize).floor();
    final hasPrev = page > 1;
    final hasNext = page * pageSize < totalItems;
    final showPager = totalItems > pageSize;

    final vcare = context.vcare;

    final isInitialLoading =
        (summaryState.fetching && summary == null) || isInitialLoadingList;

    final showEmptyState =
        !isInitialLoading &&
        !isInitialErrorList &&
        summaryState.error == null &&
        isCommissionSummaryEmpty(
          totalSales: summary?.totalSales,
          totalCommission: summary?.totalCommission,
          upcomingCount: summary?.upcomingCount ?? 0,
          needsAttentionCount: summary?.needsAttentionCount ?? 0,
          historyEmpty: isEmptyList,
        );

    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              textScaleFactor: textScaleFactor,
              hasSubtitle: false,
              title: vcareTabPageTitle(
                title: 'Sales & Commissions',
                showBack: widget.showBack,
              ),
            ),
          ),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (showEmptyState)
                  CommissionEmptyState(isAgencyTied: usesSalesHistory)
                else ...[
                  CommissionSummarySection(
                    summary: summary,
                    isLoading: summaryState.fetching && summary == null,
                    isAgencyGroup: usesSalesHistory,
                    error: summary == null ? summaryState.error : null,
                    onRetry: () => ref
                        .read(commissionSummaryStateProvider.notifier)
                        .fetchSummary(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Your earnings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        isInitialLoadingList
                            ? '—'
                            : _entryCountLabel(totalItems),
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isInitialLoadingList)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          usesSalesHistory
                              ? 'Loading sales history…'
                              : 'Loading commission history…',
                          style: TextStyle(
                            fontSize: 14,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ),
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
                      CommissionHistoryList.sales(
                        items: salesHistoryState.items,
                      )
                    else
                      CommissionHistoryList.commission(
                        items: commissionHistoryState.items,
                      ),
                    if (showPager) ...[
                      const SizedBox(height: 12),
                      CommissionPager(
                        page: page,
                        totalPages: totalPages,
                        hasPrev: hasPrev,
                        hasNext: hasNext,
                        isBusy: isRefreshingList || isInitialLoadingList,
                        onPageChange: (next) => _onPageChange(
                          next,
                          usesSalesHistory: usesSalesHistory,
                        ),
                      ),
                    ],
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
