import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

abstract class CommissionRepository {
  Future<EitherResponseOrException<CommissionSummary>> fetchSummary({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<PaginatedResult<CommissionHistoryItem>>>
      fetchHistory(
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });
}
