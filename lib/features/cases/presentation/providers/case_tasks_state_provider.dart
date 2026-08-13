import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_task.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_tasks_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'case_tasks_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CaseTasksState extends _$CaseTasksState {
  int _generation = 0;

  @override
  CaseTasksStateData build(String caseId) => const CaseTasksStateData();

  Future<void> fetchTasks({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref.read(caseTaskRepositoryProvider).fetchTasks(
      caseId,
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
      success: (tasks) {
        if (ref.mounted && generation == _generation) {
          state = state.success(tasks);
        }
      },
    );
  }

  Future<void> createTask({
    required String clientId,
    required String title,
    String? description,
    required CaseTaskStatus status,
    required String priority,
    String? assignedTo,
    String? dueDate,
    void Function(CaseTask? created, String? error)? onCompleted,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || state.mutating) return;

    if (ref.mounted) {
      state = state.mutationLoading();
    }

    final response = await ref.read(caseTaskRepositoryProvider).createTask(
      caseId: caseId,
      clientId: clientId,
      title: trimmed,
      description: description?.trim(),
      status: status,
      priority: priority,
      assignedTo: assignedTo,
      dueDate: dueDate,
    );

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.mutationFailure(error.userMessage);
        }
        onCompleted?.call(null, error.userMessage);
      },
      success: (created) async {
        await fetchTasks(forceRefresh: true);
        if (ref.mounted) {
          state = state.mutationIdle();
        }
        onCompleted?.call(created, null);
      },
    );
  }

  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    CaseTaskStatus? status,
    String? priority,
    String? assignedTo,
    bool clearAssignedTo = false,
    String? dueDate,
    String? clientId,
    void Function(CaseTask? updated, String? error)? onCompleted,
  }) async {
    if (state.mutating) return;

    if (ref.mounted) {
      state = state.mutationLoading();
    }

    final response = await ref.read(caseTaskRepositoryProvider).updateTask(
      taskId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assignedTo: assignedTo,
      clearAssignedTo: clearAssignedTo,
      dueDate: dueDate,
      clientId: clientId,
      caseId: caseId,
    );

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.mutationFailure(error.userMessage);
        }
        onCompleted?.call(null, error.userMessage);
      },
      success: (updated) async {
        await fetchTasks(forceRefresh: true);
        if (ref.mounted) {
          state = state.mutationIdle();
        }
        onCompleted?.call(updated, null);
      },
    );
  }
}
