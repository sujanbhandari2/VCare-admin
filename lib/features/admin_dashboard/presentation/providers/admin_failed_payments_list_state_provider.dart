import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_request.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_repository_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_state_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_todo_pagination.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';

part 'admin_failed_payments_list_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AdminFailedPaymentsListState extends _$AdminFailedPaymentsListState
    with PaginatedListNotifierMixin<AdminDashboardFailedPaymentTodoItem> {
  @override
  LoadableListState<AdminDashboardFailedPaymentTodoItem> build() =>
      LoadableListState<AdminDashboardFailedPaymentTodoItem>();

  @override
  bool get mounted => ref.mounted;

  @override
  bool resolveForceRefresh() => ref.read(networkFetchSessionProvider);

  @override
  Future<
      EitherResponseOrException<
          PaginatedResult<AdminDashboardFailedPaymentTodoItem>>>
      fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) async {
    final response =
        await ref.read(adminDashboardRepositoryProvider).fetchTodoList(
              AdminDashboardTodoRequest(
                page: request.page,
                limit: request.limit,
                type: AdminDashboardTodoQueryType.paymentFailed,
              ),
              forceRefresh: forceRefresh,
            );

    return response.when(
      failure: (error) => Failure<
          PaginatedResult<AdminDashboardFailedPaymentTodoItem>,
          HttpException>(error),
      success: (page) {
        final items = page.items
            .whereType<AdminDashboardFailedPaymentTodoItem>()
            .toList(growable: false);
        return Success<
            PaginatedResult<AdminDashboardFailedPaymentTodoItem>,
            HttpException>(
          PaginatedResult(
            items: items,
            pagination: buildAdminTodoPagination(
              request: request,
              rawItemCount: page.items.length,
              keptItemCount: items.length,
              loadedItemCount: request.page == 1 ? 0 : state.items.length,
              reportedTotal: page.totalCount,
            ),
          ),
        );
      },
    );
  }

  /// Refreshes this list together with the dashboard failed payments section so
  /// both views show the same data. [onlyIfLoaded] skips the list request when
  /// the screen was never opened.
  Future<void> sync({bool onlyIfLoaded = false}) async {
    await Future.wait([
      ref.read(adminDashboardStateProvider.notifier).refreshFailedPayments(),
      if (!onlyIfLoaded || state.items.isNotEmpty) refresh(),
    ]);
  }
}
