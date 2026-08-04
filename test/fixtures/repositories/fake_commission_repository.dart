import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_history_item.dart';
import 'package:vcare_admin/features/commission/domain/repositories/commission_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

class FakeCommissionRepository implements CommissionRepository {
  EitherResponseOrException<CommissionSummary> fetchSummaryResult = Success(
    const CommissionSummary(totalSales: 0, totalCommission: 0),
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

  EitherResponseOrException<PaginatedResult<SalesHistoryItem>>
  fetchSalesHistoryResult = Success(
    PaginatedResult<SalesHistoryItem>(
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
  int fetchSalesHistoryCallCount = 0;
  PaginatedListRequest? lastHistoryRequest;
  PaginatedListRequest? lastSalesHistoryRequest;
  String? lastSummaryStatus;
  String? lastSummaryAgencyGroupId;
  String? lastHistoryStatus;
  String? lastHistoryType;
  String? lastHistoryAgencyGroupId;
  bool? lastHistoryForceRefresh;
  final historyTypesCalled = <String?>[];
  String? lastSalesHistoryStatus;
  String? lastSalesHistoryAgencyGroupId;
  bool? lastSalesHistoryForceRefresh;

  @override
  Future<EitherResponseOrException<CommissionSummary>> fetchSummary({
    String? status,
    String? agencyGroupId,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    fetchSummaryCallCount++;
    lastSummaryStatus = status;
    lastSummaryAgencyGroupId = agencyGroupId;
    return fetchSummaryResult;
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<CommissionHistoryItem>>>
  fetchHistory(
    PaginatedListRequest request, {
    String? status,
    String? type,
    String? agencyGroupId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    fetchHistoryCallCount++;
    lastHistoryRequest = request;
    lastHistoryStatus = status;
    lastHistoryType = type;
    historyTypesCalled.add(type);
    lastHistoryAgencyGroupId = agencyGroupId;
    lastHistoryForceRefresh = forceRefresh;
    return fetchHistoryResult;
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<SalesHistoryItem>>>
  fetchSalesHistory(
    PaginatedListRequest request, {
    String? status,
    String? agencyGroupId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    fetchSalesHistoryCallCount++;
    lastSalesHistoryRequest = request;
    lastSalesHistoryStatus = status;
    lastSalesHistoryAgencyGroupId = agencyGroupId;
    lastSalesHistoryForceRefresh = forceRefresh;
    return fetchSalesHistoryResult;
  }
}
