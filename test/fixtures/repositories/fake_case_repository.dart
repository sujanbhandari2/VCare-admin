import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/domain/entities/cases_list_request.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

class FakeCaseRepository implements CaseRepository {
  EitherResponseOrException<ReferralCase> createCaseResult = Success(
    ReferralCase(
      id: 'case-new',
      caseNumber: 'CASENEW',
      title: 'Care Coordination',
      status: CaseStatus.newCase,
      priority: CasePriority.medium,
      caseType: 'Care Coordination',
      clientId: 'client-1',
      client: const ReferralCaseClient(
        id: 'client-1',
        firstName: 'Jane',
        lastName: 'Doe',
      ),
      createdAt: '2026-08-17T00:00:00.000Z',
      updatedAt: '2026-08-17T00:00:00.000Z',
    ),
  );

  EitherResponseOrException<List<CaseAssignee>> fetchAssigneesResult =
      const Success([
        CaseAssignee(
          id: 'user-1',
          firstName: 'Alex',
          lastName: 'Advocate',
          email: 'alex@example.com',
          role: 'Advocate',
        ),
      ]);

  CreateCaseBody? lastCreateBody;

  @override
  Future<EitherResponseOrException<ReferralCase>> createCase(
    CreateCaseBody body, {
    CancelToken? cancelToken,
  }) async {
    lastCreateBody = body;
    return createCaseResult;
  }

  @override
  Future<EitherResponseOrException<List<CaseAssignee>>> fetchAssignees({
    String? search,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    return fetchAssigneesResult;
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ReferralCase>>> fetchCases(
    CasesListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    return Success(
      PaginatedResult(
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
  }

  @override
  Future<EitherResponseOrException<ReferralCase>> fetchCaseDetail(
    String id, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EitherResponseOrException<ReferralCase>> updateCase(
    String id,
    UpdateCaseBody body, {
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EitherResponseOrException<ReferralCase>> cloneCase(
    String id, {
    String? assignedTo,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ReferralCase>>>
  fetchOtherCases(
    String caseId,
    CasesListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EitherResponseOrException<void>> setBookmark(
    String caseId, {
    required bool bookmarked,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError();
  }
}
