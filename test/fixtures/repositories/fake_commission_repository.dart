import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/features/commission/domain/repositories/commission_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

class FakeCommissionRepository implements CommissionRepository {
  EitherResponseOrException<CommissionSummary> fetchSummaryResult = Success(
    const CommissionSummary(totalSales: '0', totalCommission: '0'),
  );

  EitherResponseOrException<PaginatedResult<CommissionHistoryItem>>
      fetchHistoryResult = Success(
    PaginatedResult<CommissionHistoryItem>(
      items: const [],
      pagination: const PaginationMeta(
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 0,
        hasNext: false,
        hasPrev: false,
      ),
    ),
  );

  int fetchSummaryCallCount = 0;
  int fetchHistoryCallCount = 0;
  PaginatedListRequest? lastHistoryRequest;

  @override
  Future<EitherResponseOrException<CommissionSummary>> fetchSummary({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    fetchSummaryCallCount++;
    return fetchSummaryResult;
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<CommissionHistoryItem>>>
      fetchHistory(
    PaginatedListRequest request, {
    CancelToken? cancelToken,
  }) async {
    fetchHistoryCallCount++;
    lastHistoryRequest = request;
    return fetchHistoryResult;
  }
}
