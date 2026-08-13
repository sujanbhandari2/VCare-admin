import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/data/mappers/case_assignee_mapper.dart';
import 'package:vcare_admin/features/cases/data/mappers/referral_case_mapper.dart';
import 'package:vcare_admin/features/cases/data/models/case_assignee_model.dart';
import 'package:vcare_admin/features/cases/data/models/referral_case_model.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/domain/entities/cases_list_request.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

class CaseRepositoryImpl implements CaseRepository {
  const CaseRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  static const _bookmarkBody = {
    'entityType': 'referral_case',
    'kind': 'bookmark',
  };

  @override
  Future<EitherResponseOrException<PaginatedResult<ReferralCase>>> fetchCases(
    CasesListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.referralCases,
        queryParameters: request.toQueryParameters(),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      return PaginatedResponseParser.parse(
        response,
        (json) => ReferralCaseModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );
    });
  }

  @override
  Future<EitherResponseOrException<ReferralCase>> fetchCaseDetail(
    String id, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.referralCase(id),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => ReferralCaseModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: ReferralCaseModel.isValidApiData,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<ReferralCase>> createCase(
    CreateCaseBody body, {
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.referralCases,
        JsonRequestBody(body.toJson()),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => ReferralCaseModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: ReferralCaseModel.isValidApiData,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<ReferralCase>> updateCase(
    String id,
    UpdateCaseBody body, {
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.referralCase(id),
        JsonRequestBody(body.toJson()),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => ReferralCaseModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: ReferralCaseModel.isValidApiData,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<ReferralCase>> cloneCase(
    String id, {
    String? assignedTo,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final payload = <String, dynamic>{
        if (assignedTo != null && assignedTo.trim().isNotEmpty)
          'assignedTo': assignedTo.trim(),
      };

      final response = await apiClient.post(
        ApiEndpoints.referralCaseClone(id),
        JsonRequestBody(payload),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => ReferralCaseModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: ReferralCaseModel.isValidApiData,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ReferralCase>>>
  fetchOtherCases(
    String caseId,
    CasesListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.referralCaseOtherCases(caseId),
        queryParameters: request.toQueryParameters(),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      return PaginatedResponseParser.parse(
        response,
        (json) => ReferralCaseModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );
    });
  }

  @override
  Future<EitherResponseOrException<void>> setBookmark(
    String caseId, {
    required bool bookmarked,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final body = JsonRequestBody({
        ..._bookmarkBody,
        'entityId': caseId,
      });

      final response = bookmarked
          ? await apiClient.post(
              ApiEndpoints.meInteractions,
              body,
              isAuthenticated: true,
              cancelToken: cancelToken,
            )
          : await apiClient.delete(
              ApiEndpoints.meInteractions,
              body: body,
              isAuthenticated: true,
              cancelToken: cancelToken,
            );

      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<List<CaseAssignee>>> fetchAssignees({
    String? search,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final trimmedSearch = search?.trim();
      final response = await apiClient.get(
        ApiEndpoints.users,
        queryParameters: {
          'page': 1,
          'limit': 25,
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
          'isActive': true,
          'type': 'internal',
          if (trimmedSearch != null && trimmedSearch.isNotEmpty)
            'search': trimmedSearch,
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final parsed = PaginatedResponseParser.parse(
        response,
        (json) => CaseAssigneeModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );

      return parsed.items
          .where((assignee) => assignee.id.trim().isNotEmpty)
          .toList(growable: false);
    });
  }
}
