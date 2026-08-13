import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_assignees_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'case_assignees_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CaseAssigneesState extends _$CaseAssigneesState {
  int _generation = 0;

  @override
  CaseAssigneesStateData build() => const CaseAssigneesStateData();

  Future<void> search(
    String query, {
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;
    final trimmed = query.trim();

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref.read(caseRepositoryProvider).fetchAssignees(
      search: trimmed.isEmpty ? null : trimmed,
      cancelToken: cancelToken,
      forceRefresh: forceRefresh,
    );

    if (!ref.mounted || generation != _generation) return;

    response.when(
      failure: (error) {
        if (ref.mounted && generation == _generation) {
          state = state.failure(error.userMessage);
        }
      },
      success: (assignees) {
        if (ref.mounted && generation == _generation) {
          state = state.success(assignees);
        }
      },
    );
  }
}
