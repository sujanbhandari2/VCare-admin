import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/task_detail/presentation/state/task_detail_assignees_state.dart';
import 'package:vcare_admin/features/users/presentation/providers/internal_users_repository_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'task_detail_assignees_state_provider.g.dart';

/// Team members a task can be assigned to. The web drawer loads one page of
/// users and filters locally, so this does the same.
@Riverpod(keepAlive: true)
class TaskDetailAssigneesState extends _$TaskDetailAssigneesState {
  static const int _limit = 100;

  @override
  TaskDetailAssigneesStateData build() => const TaskDetailAssigneesStateData();

  Future<void> fetchAssignees({
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    if (state.fetching) return;

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(internalUsersRepositoryProvider)
        .fetchInternalUsers(
          limit: _limit,
          forceRefresh: forceRefresh,
          cancelToken: cancelToken,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
      },
      success: (users) {
        if (ref.mounted) {
          state = state.success(users);
        }
      },
    );
  }
}
