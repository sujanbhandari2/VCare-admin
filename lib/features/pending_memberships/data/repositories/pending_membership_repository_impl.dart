import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/pending_memberships/data/mappers/membership_approval_mapper.dart';
import 'package:vcare_admin/features/pending_memberships/data/mappers/pending_membership_mapper.dart';
import 'package:vcare_admin/features/pending_memberships/data/models/membership_approval_model.dart';
import 'package:vcare_admin/features/pending_memberships/data/models/pending_membership_model.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/membership_approval.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_memberships_request.dart';
import 'package:vcare_admin/features/pending_memberships/domain/repositories/pending_membership_repository.dart';
import 'package:vcare_admin/features/pending_memberships/utils/membership_parsers.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

class PendingMembershipRepositoryImpl implements PendingMembershipRepository {
  const PendingMembershipRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<PaginatedResult<PendingMembership>>>
  fetchMemberships(
    PendingMembershipsRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.enrollments,
        queryParameters: request.toQueryParameters(),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      return _parseMembershipPage(response);
    });
  }

  @override
  Future<EitherResponseOrException<PendingMembership>> fetchMembership(
    String membershipId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.enrollmentById(membershipId),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => PendingMembershipModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<MembershipAssociatedResult>>
  fetchAssociatedMemberships(
    String clientId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.enrollmentsAssociateMembership(clientId),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => MembershipAssociatedResultModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<PendingMembership>>>
  fetchRelevantMemberships(
    String clientId, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.enrollmentsRelevantMembership(clientId),
        queryParameters: {
          'page': page,
          'limit': limit,
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      return _parseMembershipPage(response);
    });
  }

  @override
  Future<EitherResponseOrException<MembershipApprovalCompute>> computeApproval({
    required String membershipId,
    required DateTime date,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.enrollmentsApproveCompute,
        JsonRequestBody({
          'enrollmentId': membershipId,
          'date': formatMembershipApiDate(date),
        }),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => MembershipApprovalComputeModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<PendingMembership>> approveMembership({
    required String membershipId,
    required DateTime date,
    CancelToken? cancelToken,
  }) {
    return _postMembershipAction(
      endpoint: ApiEndpoints.enrollmentsApprove,
      body: {
        'enrollmentId': membershipId,
        'date': formatMembershipApiDate(date),
      },
      cancelToken: cancelToken,
    );
  }

  @override
  Future<EitherResponseOrException<PendingMembership>> declineMembership({
    required String membershipId,
    required String note,
    CancelToken? cancelToken,
  }) {
    final trimmedNote = note.trim();

    return _postMembershipAction(
      endpoint: ApiEndpoints.enrollmentsCancel,
      body: {
        'enrollmentId': membershipId,
        if (trimmedNote.isNotEmpty) 'note': trimmedNote,
      },
      cancelToken: cancelToken,
    );
  }

  Future<EitherResponseOrException<PendingMembership>> _postMembershipAction({
    required String endpoint,
    required Map<String, dynamic> body,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        endpoint,
        JsonRequestBody(body),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => PendingMembershipModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  PaginatedResult<PendingMembership> _parseMembershipPage(
    Response<dynamic> response,
  ) {
    final page = PaginatedResponseParser.parse(
      response,
      (json) => PendingMembershipModel.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );

    return PaginatedResult(
      items: page.items
          .map((model) => model.toEntity())
          .toList(growable: false),
      pagination: page.pagination,
    );
  }
}
