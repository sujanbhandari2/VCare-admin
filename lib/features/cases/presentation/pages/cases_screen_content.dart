import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/cases_list_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_row_card.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_empty_state.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_filter_bar.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_header_action.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_list_skeleton.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_search_bar.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Cases list body — only mounted when case management is enabled.
class CasesScreenContent extends ConsumerStatefulWidget {
  const CasesScreenContent({super.key});

  @override
  ConsumerState<CasesScreenContent> createState() => _CasesScreenContentState();
}

class _CasesScreenContentState extends ConsumerState<CasesScreenContent> {
  static const double _loadMoreTriggerThreshold = 240;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _scrolled = false;
  bool _searchFocused = false;
  bool _isLoadMoreRequested = false;
  bool _searchReloadActive = false;
  bool _filterReloadActive = false;
  int _searchGeneration = 0;
  int _filterGeneration = 0;

  /// A filter change or a search is replacing the list, so the stale rows are
  /// swapped for skeletons instead of sitting there looking current.
  bool get _isReloadingList => _searchReloadActive || _filterReloadActive;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(casesListStateProvider.notifier).loadInitial();
    });
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 8;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }

    final listState = ref.read(casesListStateProvider);
    final shouldLoadMore =
        listState.hasMore &&
        listState.items.isNotEmpty &&
        !listState.isLoadingMore &&
        !listState.isRefreshing &&
        listState.loadMoreErrorMessage == null &&
        !listState.isInitialLoading &&
        !listState.isInitialError &&
        !_isLoadMoreRequested &&
        !_isReloadingList &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= _loadMoreTriggerThreshold;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      ref.read(casesListStateProvider.notifier).loadMore().whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final generation = ++_searchGeneration;
    if (!_searchReloadActive) {
      setState(() => _searchReloadActive = true);
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      await ref.read(casesListStateProvider.notifier).search(value);
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _searchReloadActive = false);
    });
  }

  /// Keeps the skeleton up for the whole filter round trip, and only lets the
  /// newest request clear it so overlapping taps do not flicker the list back.
  Future<void> _runFilterReload(Future<void> Function() action) async {
    final generation = ++_filterGeneration;
    if (!_filterReloadActive) {
      setState(() => _filterReloadActive = true);
    }

    await action();
    if (!mounted || generation != _filterGeneration) return;
    setState(() => _filterReloadActive = false);
  }

  Future<void> _onRefresh() async {
    await ref.read(casesListStateProvider.notifier).refresh();
  }

  Future<void> _onStatusChanged(CaseStatus? status) {
    return _runFilterReload(
      () => ref.read(casesListStateProvider.notifier).setStatus(status),
    );
  }

  Future<void> _onPriorityChanged(CasePriority? priority) {
    return _runFilterReload(
      () => ref.read(casesListStateProvider.notifier).setPriority(priority),
    );
  }

  Future<void> _onBookmarkedOnlyChanged(bool value) {
    return _runFilterReload(
      () => ref.read(casesListStateProvider.notifier).setBookmarkedOnly(value),
    );
  }

  Future<void> _onClearFilters() {
    final extras = <String, dynamic>{};
    final search = ref
        .read(casesListStateProvider)
        .extras?[PaginatedListNotifierMixin.searchExtraKey];
    if (search is String) {
      extras[PaginatedListNotifierMixin.searchExtraKey] = search;
    }

    return _runFilterReload(
      () => ref
          .read(casesListStateProvider.notifier)
          .loadInitial(extras: extras, forceRefresh: true),
    );
  }

  void _onToggleBookmark(String caseId) {
    ref.read(casesListStateProvider.notifier).toggleBookmark(
      caseId,
      onCompleted: (success, error) {
        if (!mounted || success) return;
        context.showVcareToast(
          title: error ?? 'Unable to update bookmark',
          variant: VcareToastVariant.destructive,
        );
      },
    );
  }

  void _openCreateCase() {
    context.pushNamed(AppRouter.caseCreateName);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(casesListStateProvider);
    final status = ref.watch(
      casesListStateProvider.select((state) {
        final value = state.extras?[CasesListState.statusExtraKey];
        return value is CaseStatus ? value : null;
      }),
    );
    final priority = ref.watch(
      casesListStateProvider.select((state) {
        final value = state.extras?[CasesListState.priorityExtraKey];
        return value is CasePriority ? value : null;
      }),
    );
    final bookmarkedOnly = ref.watch(
      casesListStateProvider.select((state) {
        final value = state.extras?[CasesListState.bookmarkedOnlyExtraKey];
        return value is bool ? value : false;
      }),
    );
    final cases = listState.items;
    final showSkeleton = listState.isInitialLoading || _isReloadingList;
    final subtitle = buildCasesSubtitle(
      listState.totalItems,
      isLoading: showSkeleton,
    );
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: VcareRefreshScrollView(
        controller: _scrollController,
        onRefresh: _onRefresh,
        padForMobileBottomNav: true,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              textScaleFactor: textScaleFactor,
              hasSubtitle: true,
              showBottomBorder: _scrolled,
              title: vcareTabPageTitle(
                title: 'Cases',
                subtitle: subtitle,
                action: CasesHeaderAction(onPressed: _openCreateCase),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: CasesFilterHeaderDelegate(
              status: status,
              priority: priority,
              bookmarkedOnly: bookmarkedOnly,
              onStatusChanged: _onStatusChanged,
              onPriorityChanged: _onPriorityChanged,
              onBookmarkedOnlyChanged: _onBookmarkedOnlyChanged,
              onClearFilters: _onClearFilters,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: VcareStickySearchHeaderDelegate(
              scrolled: _scrolled,
              focused: _searchFocused,
              controller: _searchController,
              onChanged: _onSearchChanged,
              onFocusChange: (focused) {
                if (focused != _searchFocused) {
                  setState(() => _searchFocused = focused);
                }
              },
              placeholder: 'Search by client, case number or type',
            ),
          ),
          if (showSkeleton)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: CasesListSkeleton()),
            )
          else if (listState.isInitialError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: VcareErrorStatePanel(
                title: 'Unable to load cases',
                message: listState.operation.errorMessage,
                actionLabel: context.appLocalization.retry,
                onAction: () =>
                    ref.read(casesListStateProvider.notifier).loadInitial(),
              ),
            )
          else if (listState.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: CasesEmptyState()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: cases.length + (listState.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= cases.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final referralCase = cases[index];
                  return CaseRowCard(
                    referralCase: referralCase,
                    onTap: () => context.pushNamed(
                      AppRouter.caseDetailName,
                      pathParameters: {'id': referralCase.id},
                    ),
                    onToggleBookmark: () => _onToggleBookmark(referralCase.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
