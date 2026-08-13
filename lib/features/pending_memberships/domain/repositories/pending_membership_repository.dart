import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/membership_approval.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_memberships_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

abstract class PendingMembershipRepository {
  Future<EitherResponseOrException<PaginatedResult<PendingMembership>>>
  fetchMemberships(
    PendingMembershipsRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<PendingMembership>> fetchMembership(
    String membershipId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<MembershipAssociatedResult>>
  fetchAssociatedMemberships(
    String clientId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<PaginatedResult<PendingMembership>>>
  fetchRelevantMemberships(
    String clientId, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  /// Pricing preview for an approval. [date] is the billing start (`yyyy-MM-dd`).
  Future<EitherResponseOrException<MembershipApprovalCompute>> computeApproval({
    required String membershipId,
    required DateTime date,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  });

  Future<EitherResponseOrException<PendingMembership>> approveMembership({
    required String membershipId,
    required DateTime date,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<PendingMembership>> declineMembership({
    required String membershipId,
    required String note,
    CancelToken? cancelToken,
  });
}
