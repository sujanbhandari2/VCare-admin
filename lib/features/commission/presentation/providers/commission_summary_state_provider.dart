import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_repository_provider.dart';
import 'package:vcare_admin/features/commission/presentation/state/commission_summary_state.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'commission_summary_state_provider.g.dart';

/// Matches web `AGGREGATE_LIMIT` in useCommissions.
const int _aggregateLimit = 100;

@Riverpod(keepAlive: true)
class CommissionSummaryStateNotifier extends _$CommissionSummaryStateNotifier {
  CommissionFilter _filter = CommissionFilter.all;

  CommissionFilter get filter => _filter;

  @override
  CommissionSummaryState build() => const CommissionSummaryState();

  Future<void> setFilter(CommissionFilter filter) async {
    if (_filter == filter) return;
    _filter = filter;
    await fetchSummary(forceRefresh: true);
  }

  Future<void> fetchSummary({
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(CommissionSummary? summary)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final agencyGroupId = _resolveAgencyGroupId();
    final repository = ref.read(commissionRepositoryProvider);

    // Do not send agencyGroupId on summary — scoped to the caller (web parity).
    final summaryResponse = await repository.fetchSummary(
      status: _filter.apiStatus,
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );

    final aggregateRequest = PaginatedListRequest(
      page: 1,
      limit: _aggregateLimit,
    );

    // parity: useCommissions upcoming + commission-only aggregate queries
    final upcomingResponse = await repository.fetchHistory(
      aggregateRequest,
      type: 'upcoming',
      agencyGroupId: agencyGroupId,
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );
    final commissionOnlyResponse = await repository.fetchHistory(
      aggregateRequest,
      type: 'commission',
      agencyGroupId: agencyGroupId,
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );

    summaryResponse.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (base) {
        final upcomingItems =
            upcomingResponse.dataOrNull?.items ??
            const <CommissionHistoryItem>[];
        final commissionItems =
            commissionOnlyResponse.dataOrNull?.items ??
            const <CommissionHistoryItem>[];
        final upcoming = aggregateSaleTotals(upcomingItems);
        final failedEntries = commissionItems.where(
          (entry) =>
              entry.paymentFailed ||
              resolveCommissionStatusLabel(entry) == 'Failed',
        );
        final needsAttention = aggregateSaleTotals(failedEntries);

        final summary = base.copyWithAggregates(
          upcomingSales: upcoming.total,
          upcomingCount: upcoming.count,
          needsAttentionSales: needsAttention.total,
          needsAttentionCount: needsAttention.count,
        );

        if (ref.mounted) {
          state = state.success(summary);
        }
        onCompleted?.call(summary);
      },
    );
  }

  String? _resolveAgencyGroupId() {
    final id = ref.read(localProfileStateProvider).agencyGroupId?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }
}
