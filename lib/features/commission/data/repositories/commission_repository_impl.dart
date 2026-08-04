import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/data/mappers/commission_history_item_mapper.dart';
import 'package:vcare_admin/features/commission/data/mappers/commission_summary_mapper.dart';
import 'package:vcare_admin/features/commission/data/mappers/sales_history_item_mapper.dart';
import 'package:vcare_admin/features/commission/data/models/commission_history_item_model.dart';
import 'package:vcare_admin/features/commission/data/models/commission_summary_model.dart';
import 'package:vcare_admin/features/commission/data/models/sales_history_item_model.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_history_item.dart';
import 'package:vcare_admin/features/commission/domain/repositories/commission_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

class CommissionRepositoryImpl implements CommissionRepository {
  const CommissionRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<CommissionSummary>> fetchSummary({
    String? status,
    String? agencyGroupId,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final queryParameters = <String, dynamic>{};
      final trimmedStatus = status?.trim();
      if (trimmedStatus != null && trimmedStatus.isNotEmpty) {
        queryParameters['status'] = trimmedStatus;
      }
      final trimmedAgencyGroupId = agencyGroupId?.trim();
      if (trimmedAgencyGroupId != null && trimmedAgencyGroupId.isNotEmpty) {
        queryParameters['agencyGroupId'] = trimmedAgencyGroupId;
      }

      final response = await apiClient.get(
        ApiEndpoints.agentCommissionSummary,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        isAuthenticated: true,
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => CommissionSummaryModel.fromJson(data as Map<String, dynamic>),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
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
  }) {
    return safeNetworkCall(() async {
      final queryParameters = _historyQueryParameters(
        request,
        sortBy: 'createdAt',
        status: status,
        type: type,
        agencyGroupId: agencyGroupId,
      );

      final response = await apiClient.get(
        ApiEndpoints.agentCommissionHistory,
        queryParameters: queryParameters,
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      return PaginatedResponseParser.parse(
        response,
        (json) => CommissionHistoryItemModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );
    });
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<SalesHistoryItem>>>
  fetchSalesHistory(
    PaginatedListRequest request, {
    String? status,
    String? agencyGroupId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final queryParameters = _historyQueryParameters(
        request,
        sortBy: 'transactionDate',
        status: status,
        agencyGroupId: agencyGroupId,
      );

      final response = await apiClient.get(
        ApiEndpoints.agentSalesHistory,
        queryParameters: queryParameters,
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      return PaginatedResponseParser.parse(
        response,
        (json) => SalesHistoryItemModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );
    });
  }

  Map<String, dynamic> _historyQueryParameters(
    PaginatedListRequest request, {
    required String sortBy,
    String? status,
    String? type,
    String? agencyGroupId,
  }) {
    final queryParameters = <String, dynamic>{
      ...request.toQueryParameters(),
      'sortBy': sortBy,
      'sortOrder': 'desc',
    };
    final trimmedStatus = status?.trim();
    if (trimmedStatus != null && trimmedStatus.isNotEmpty) {
      queryParameters['status'] = trimmedStatus;
    }
    final trimmedType = type?.trim();
    if (trimmedType != null && trimmedType.isNotEmpty) {
      queryParameters['type'] = trimmedType;
    }
    final trimmedAgencyGroupId = agencyGroupId?.trim();
    if (trimmedAgencyGroupId != null && trimmedAgencyGroupId.isNotEmpty) {
      queryParameters['agencyGroupId'] = trimmedAgencyGroupId;
    }
    return queryParameters;
  }
}
