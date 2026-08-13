import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';
import 'package:vcare_admin/features/task_detail/presentation/providers/task_detail_repository_provider.dart';
import 'package:vcare_admin/features/task_detail/presentation/state/task_detail_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'task_detail_state_provider.g.dart';

/// Family notifier for a single task, keyed by task id.
@Riverpod(keepAlive: true)
class TaskDetailState extends _$TaskDetailState {
  int _generation = 0;

  @override
  TaskDetailStateData build(String taskId) => const TaskDetailStateData();

  Future<void> fetchDetail({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(taskDetailRepositoryProvider)
        .fetchTaskDetail(
          taskId: taskId,
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
      success: (detail) {
        if (ref.mounted && generation == _generation) {
          state = state.success(detail);
        }
      },
    );
  }

  Future<void> updateTask({
    required String title,
    required String? description,
    required TaskDetailStatus status,
    required TaskDetailPriority priority,
    required String assignedTo,
    required String? dueDateIso,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final current = state.data;
    if (current == null || state.updating) return;

    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final response = await ref.read(taskDetailRepositoryProvider).updateTask(
      taskId: taskId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assignedTo: assignedTo,
      dueDateIso: dueDateIso,
      category: current.apiCategory,
      categoryReferenceId: current.linkedReferenceId,
      clientId: current.clientId,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (detail) {
        if (ref.mounted) {
          state = state.updateSuccess(detail);
        }
        onCompleted?.call(true, null);
        // The PATCH response can come back without the nested assignee/creator,
        // so re-read the task to keep names on screen instead of raw ids.
        fetchDetail(forceRefresh: true);
      },
    );
  }
}
