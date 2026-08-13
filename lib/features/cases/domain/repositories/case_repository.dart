import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/domain/entities/cases_list_request.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

abstract class CaseRepository {
  Future<EitherResponseOrException<PaginatedResult<ReferralCase>>> fetchCases(
    CasesListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<ReferralCase>> fetchCaseDetail(
    String id, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<ReferralCase>> createCase(
    CreateCaseBody body, {
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<ReferralCase>> updateCase(
    String id,
    UpdateCaseBody body, {
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<ReferralCase>> cloneCase(
    String id, {
    String? assignedTo,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<PaginatedResult<ReferralCase>>>
  fetchOtherCases(
    String caseId,
    CasesListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<void>> setBookmark(
    String caseId, {
    required bool bookmarked,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<List<CaseAssignee>>> fetchAssignees({
    String? search,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });
}
