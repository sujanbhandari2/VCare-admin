import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_state_provider.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_memberships_request.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/providers/pending_membership_repository_provider.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_pagination.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';

part 'pending_memberships_list_state_provider.g.dart';

/// Submitted enrollments awaiting review — parity with the web memberships
/// list filtered to `status=SUBMITTED`.
@Riverpod(keepAlive: true)
class PendingMembershipsListState extends _$PendingMembershipsListState
    with PaginatedListNotifierMixin<PendingMembership> {
  @override
  LoadableListState<PendingMembership> build() =>
      LoadableListState<PendingMembership>();

  @override
  bool get mounted => ref.mounted;

  @override
  bool resolveForceRefresh() => ref.read(networkFetchSessionProvider);

  @override
  Future<EitherResponseOrException<PaginatedResult<PendingMembership>>>
  fetchPage(PaginatedListRequest request, {bool forceRefresh = false}) async {
    final isFirstPage = request.page == 1;
    final loadedItems = isFirstPage ? const <PendingMembership>[] : state.items;

    final response = await ref
        .read(pendingMembershipRepositoryProvider)
        .fetchMemberships(
          PendingMembershipsRequest(
            page: request.page,
            limit: request.limit,
            search: request.search,
          ),
          forceRefresh: forceRefresh,
        );

    return response.when(
      failure: (error) =>
          Failure<PaginatedResult<PendingMembership>, HttpException>(error),
      success: (page) {
        // Reviewing a membership removes it server-side, which shifts every
        // later page; drop rows already on screen so nothing repeats.
        final loadedIds = loadedItems.map((item) => item.id).toSet();
        final items = isFirstPage
            ? page.items
            : page.items
                  .where((item) => !loadedIds.contains(item.id))
                  .toList(growable: false);

        return Success<PaginatedResult<PendingMembership>, HttpException>(
          PaginatedResult(
            items: items,
            pagination: buildPendingMembershipPagination(
              page: request.page,
              limit: request.limit,
              rawItemCount: page.items.length,
              keptItemCount: items.length,
              loadedItemCount: loadedItems.length,
              reported: page.pagination,
            ),
          ),
        );
      },
    );
  }

  /// Drops a reviewed membership in place so the reviewer keeps their scroll
  /// position and already-loaded pages, then re-reads the dashboard count.
  Future<void> removeMembership(String membershipId) async {
    final remaining = state.items
        .where((membership) => membership.id != membershipId)
        .toList(growable: false);

    if (ref.mounted && remaining.length != state.items.length) {
      final total = state.totalItems > remaining.length
          ? state.totalItems - 1
          : remaining.length;
      state = state.success(items: remaining, total: total);
    }

    await ref
        .read(adminDashboardStateProvider.notifier)
        .refreshPendingMemberships();
  }

  /// Refreshes this list together with the dashboard stat card so both views
  /// agree after an approve or decline.
  Future<void> sync({bool onlyIfLoaded = false}) async {
    await Future.wait([
      ref
          .read(adminDashboardStateProvider.notifier)
          .refreshPendingMemberships(),
      if (!onlyIfLoaded || state.items.isNotEmpty) refresh(),
    ]);
  }
}
