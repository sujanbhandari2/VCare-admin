import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/cases_list_request.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';

part 'case_other_cases_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CaseOtherCasesState extends _$CaseOtherCasesState
    with PaginatedListNotifierMixin<ReferralCase> {
  @override
  LoadableListState<ReferralCase> build(String caseId) {
    return LoadableListState<ReferralCase>();
  }

  @override
  bool get mounted => ref.mounted;

  @override
  int get pageSize => 10;

  @override
  bool resolveForceRefresh() => true;

  @override
  Future<EitherResponseOrException<PaginatedResult<ReferralCase>>> fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) {
    return ref.read(caseRepositoryProvider).fetchOtherCases(
      caseId,
      CasesListRequest(
        page: request.page,
        limit: request.limit,
        search: request.search,
        bookmarkedFirst: false,
      ),
      forceRefresh: forceRefresh,
    );
  }
}
