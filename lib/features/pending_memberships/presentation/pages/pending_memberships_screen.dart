import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/providers/pending_memberships_list_state_provider.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_approve_sheet.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_detail_sheet.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_row.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';

/// Submitted memberships awaiting review — the mobile counterpart of the web
/// memberships page filtered to pending items.
class PendingMembershipsScreen extends ConsumerStatefulWidget {
  const PendingMembershipsScreen({super.key});

  @override
  ConsumerState<PendingMembershipsScreen> createState() =>
      _PendingMembershipsScreenState();
}

class _PendingMembershipsScreenState
    extends ConsumerState<PendingMembershipsScreen> {
  static const double _loadMoreTriggerThreshold = 240;

  final _scrollController = ScrollController();

  bool _isLoadMoreRequested = false;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(pendingMembershipsListStateProvider);
      if (state.isInitialLoading || state.isRefreshing) return;

      final notifier = ref.read(pendingMembershipsListStateProvider.notifier);
      if (state.items.isEmpty) {
        if (!state.isInitialError) notifier.loadInitial();
        return;
      }

      notifier.refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled =
        _scrollController.hasClients && _scrollController.position.pixels > 0;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }

    final listState = ref.read(pendingMembershipsListStateProvider);
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
          .read(pendingMembershipsListStateProvider.notifier)
          .loadMore()
          .whenComplete(() {
            if (mounted) {
              _isLoadMoreRequested = false;
            }
          });
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(pendingMembershipsListStateProvider.notifier).sync();
  }

  Future<void> _openMembership(PendingMembership membership) async {
    final reviewed = await PendingMembershipDetailSheet.show(
      context,
      membership: membership,
    );
    if (reviewed != true || !mounted) return;

    await _onReviewed(membership);
  }

  Future<void> _approveMembership(PendingMembership membership) async {
    final approved = await PendingMembershipApproveSheet.show(
      context,
      membership: membership,
    );
    if (approved != true || !mounted) return;

    await _onReviewed(membership);
  }

  /// A reviewed membership leaves the pending list, so drop just that row
  /// instead of reloading page 1 and throwing the reviewer back to the top.
  Future<void> _onReviewed(PendingMembership membership) async {
    await ref
        .read(pendingMembershipsListStateProvider.notifier)
        .removeMembership(membership.id);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(pendingMembershipsListStateProvider);
    final items = listState.items;
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        controller: _scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              textScaleFactor: textScaleFactor,
              hasSubtitle: true,
              showBottomBorder: _scrolled,
              title: vcareTabPageTitle(
                title: 'Pending Memberships',
                subtitle: listState.totalItems > 0
                    ? '${listState.totalItems} awaiting review'
                    : 'Review submitted membership requests',
                showBack: true,
              ),
            ),
          ),
          if (listState.isInitialLoading && items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (listState.isInitialError && items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: VcareErrorStatePanel(
                title: 'Unable to load pending memberships',
                message: listState.operation.errorMessage,
                actionLabel: 'Try again',
                onAction: () => ref
                    .read(pendingMembershipsListStateProvider.notifier)
                    .loadInitial(),
              ),
            )
          else if (items.isEmpty)
            SliverPadding(
              padding: context.mobileShellScrollPadding,
              sliver: const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: VcareEmptyStateCard(
                    icon: LucideIcons.badgeCheck,
                    title: 'No pending memberships',
                    description:
                        'Submitted memberships will show up here for review.',
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: context.mobileShellScrollPadding.copyWith(bottom: 0),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final membership = items[index];
                  return PendingMembershipRow(
                    membership: membership,
                    onTap: () => _openMembership(membership),
                    onApprove: () => _approveMembership(membership),
                  );
                },
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              context.mobileShellBottomContentPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: _LoadMoreFooter(
                loadingMore: listState.isLoadingMore,
                errorMessage: listState.loadMoreErrorMessage,
                onRetry: () => ref
                    .read(pendingMembershipsListStateProvider.notifier)
                    .loadMore(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paging status under the list: the next-page spinner, or a retry when a page
/// request failed (auto-loading stops until the reviewer retries).
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.loadingMore,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool loadingMore;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final message = errorMessage;
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.vcare.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: onRetry, child: const Text('Load more')),
        ],
      ),
    );
  }
}
