import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/cases_list_request.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'cases_list_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CasesListState extends _$CasesListState
    with PaginatedListNotifierMixin<ReferralCase> {
  static const String statusExtraKey = 'status';
  static const String priorityExtraKey = 'priority';
  static const String bookmarkedOnlyExtraKey = 'bookmarkedOnly';

  @override
  LoadableListState<ReferralCase> build() => LoadableListState<ReferralCase>();

  @override
  bool get mounted => ref.mounted;

  @override
  bool resolveForceRefresh() => ref.read(networkFetchSessionProvider);

  CaseStatus? get status {
    final value = state.extras?[statusExtraKey];
    return value is CaseStatus ? value : null;
  }

  CasePriority? get priority {
    final value = state.extras?[priorityExtraKey];
    return value is CasePriority ? value : null;
  }

  bool get bookmarkedOnly {
    final value = state.extras?[bookmarkedOnlyExtraKey];
    return value is bool ? value : false;
  }

  Future<void> setStatus(CaseStatus? next) async {
    if (status == next &&
        (state.items.isNotEmpty || state.isInitialLoading)) {
      return;
    }

    final extras = <String, dynamic>{...?state.extras};
    if (next == null) {
      extras.remove(statusExtraKey);
    } else {
      extras[statusExtraKey] = next;
    }

    await loadInitial(extras: extras, forceRefresh: true);
  }

  Future<void> setPriority(CasePriority? next) async {
    if (priority == next &&
        (state.items.isNotEmpty || state.isInitialLoading)) {
      return;
    }

    final extras = <String, dynamic>{...?state.extras};
    if (next == null) {
      extras.remove(priorityExtraKey);
    } else {
      extras[priorityExtraKey] = next;
    }

    await loadInitial(extras: extras, forceRefresh: true);
  }

  Future<void> setBookmarkedOnly(bool value) async {
    if (bookmarkedOnly == value &&
        (state.items.isNotEmpty || state.isInitialLoading)) {
      return;
    }

    await loadInitial(
      extras: <String, dynamic>{
        ...?state.extras,
        bookmarkedOnlyExtraKey: value,
      },
      forceRefresh: true,
    );
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ReferralCase>>> fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) {
    return ref.read(caseRepositoryProvider).fetchCases(
      CasesListRequest(
        page: request.page,
        limit: request.limit,
        search: request.search,
        status: status,
        priority: priority,
        bookmarkedOnly: bookmarkedOnly,
      ),
      forceRefresh: forceRefresh,
    );
  }

  Future<void> toggleBookmark(
    String caseId, {
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final index = state.items.indexWhere((item) => item.id == caseId);
    if (index < 0 || !mounted) return;

    final current = state.items[index];
    final nextBookmarked = !current.isBookmarked;
    final optimistic = List<ReferralCase>.of(state.items);
    optimistic[index] = current.copyWith(isBookmarked: nextBookmarked);

    if (mounted) {
      state = state.success(items: optimistic, total: state.totalItems);
    }

    final response = await ref.read(caseRepositoryProvider).setBookmark(
      caseId,
      bookmarked: nextBookmarked,
    );

    response.when(
      failure: (error) {
        if (!mounted) {
          onCompleted?.call(false, error.userMessage);
          return;
        }

        final rollback = List<ReferralCase>.of(state.items);
        final rollbackIndex = rollback.indexWhere((item) => item.id == caseId);
        if (rollbackIndex >= 0) {
          rollback[rollbackIndex] = current;
          state = state.success(items: rollback, total: state.totalItems);
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) {
        onCompleted?.call(true, null);
      },
    );
  }
}
