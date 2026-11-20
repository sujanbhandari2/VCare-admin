import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_mutations.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_task_repository_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_tasks_list_state_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_tasks_preview_state_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/state/my_task_detail_state.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_state_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'my_task_detail_state_provider.g.dart';

@Riverpod(keepAlive: true)
class MyTaskDetailStateNotifier extends _$MyTaskDetailStateNotifier {
  int _generation = 0;

  @override
  MyTaskDetailState build(String taskId) => const MyTaskDetailState();

  Future<void> fetchDetail({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .fetchTask(
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
      success: (task) {
        if (ref.mounted && generation == _generation) {
          state = state.success(task);
        }
      },
    );

    await fetchNotes(forceRefresh: forceRefresh, cancelToken: cancelToken);
  }

  Future<void> fetchNotes({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.notesLoadingState();
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .fetchNotes(
          taskId: taskId,
          cancelToken: cancelToken,
          forceRefresh: forceRefresh,
        );

    if (!ref.mounted) return;

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.notesFailure(error.userMessage);
        }
      },
      success: (notes) {
        if (ref.mounted) {
          state = state.notesSuccess(notes);
        }
      },
    );
  }

  Future<void> updateTask({
    required MyTaskUpdateRequest request,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    if (state.data == null || state.updating) return;

    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .updateTask(taskId: taskId, request: request);

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (task) async {
        if (ref.mounted) {
          state = state.updateSuccess(task);
        }
        onCompleted?.call(true, null);
        await _syncLists();
        await fetchDetail(forceRefresh: true);
      },
    );
  }

  Future<void> createTask({
    required MyTaskCreateRequest request,
    void Function(MyTask? task, String? error)? onCompleted,
  }) async {
    // Create uses the shared repository; this notifier is keyed by id so
    // creation is typically driven from the list screen. Kept for symmetry.
    if (state.updating) return;
    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .createTask(request);

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        onCompleted?.call(null, error.userMessage);
      },
      success: (task) async {
        if (ref.mounted) {
          state = state.updateSuccess(task);
        }
        onCompleted?.call(task, null);
        await _syncLists();
      },
    );
  }

  Future<bool> addNote(String note) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) return false;

    final response = await ref
        .read(myTaskRepositoryProvider)
        .addNote(taskId: taskId, note: trimmed);

    return response.when(
      failure: (_) => false,
      success: (_) async {
        await fetchNotes(forceRefresh: true);
        return true;
      },
    );
  }

  Future<bool> updateNote({
    required String noteId,
    required String note,
  }) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) return false;

    final response = await ref
        .read(myTaskRepositoryProvider)
        .updateNote(taskId: taskId, noteId: noteId, note: trimmed);

    return response.when(
      failure: (_) => false,
      success: (_) async {
        await fetchNotes(forceRefresh: true);
        return true;
      },
    );
  }

  Future<bool> deleteNote(String noteId) async {
    final response = await ref
        .read(myTaskRepositoryProvider)
        .deleteNote(taskId: taskId, noteId: noteId);

    return response.when(
      failure: (_) => false,
      success: (_) async {
        await fetchNotes(forceRefresh: true);
        return true;
      },
    );
  }

  Future<bool> snooze({
    required DateTime until,
    String? notes,
    void Function(String? error)? onError,
  }) async {
    if (state.updating) return false;
    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .snoozeTask(
          taskId: taskId,
          request: MyTaskSnoozeRequest(
            snoozedTillIso: until.toUtc().toIso8601String(),
            notes: notes,
          ),
        );

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (task) async {
        if (ref.mounted) {
          state = state.updateSuccess(task);
        }
        await _syncLists();
        return true;
      },
    );
  }

  Future<bool> resume({void Function(String? error)? onError}) async {
    if (state.updating) return false;
    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .snoozeTask(
          taskId: taskId,
          request: const MyTaskSnoozeRequest(snoozedTillIso: null),
        );

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (task) async {
        if (ref.mounted) {
          state = state.updateSuccess(task);
        }
        await _syncLists();
        return true;
      },
    );
  }

  Future<bool> delete({void Function(String? error)? onError}) async {
    if (state.updating) return false;
    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .deleteTask(taskId: taskId);

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (_) async {
        await _syncLists();
        return true;
      },
    );
  }

  Future<void> _syncLists() async {
    await Future.wait([
      ref.read(myTasksListStateProvider.notifier).refresh(),
      ref.read(myTasksPreviewStateProvider.notifier).refresh(),
      ref.read(adminDashboardStateProvider.notifier).load(forceRefresh: true),
    ]);
  }
}

/// Standalone create flow (not keyed by an existing task id).
@Riverpod(keepAlive: true)
class MyTaskCreateStateNotifier extends _$MyTaskCreateStateNotifier {
  @override
  MyTaskDetailState build() => const MyTaskDetailState();

  Future<MyTask?> create({
    required MyTaskCreateRequest request,
    void Function(String? error)? onError,
  }) async {
    if (state.updating) return null;
    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .createTask(request);

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        onError?.call(error.userMessage);
        return null;
      },
      success: (task) async {
        if (ref.mounted) {
          state = state.updateSuccess(task);
        }
        await Future.wait([
          ref.read(myTasksListStateProvider.notifier).refresh(),
          ref.read(myTasksPreviewStateProvider.notifier).refresh(),
          ref
              .read(adminDashboardStateProvider.notifier)
              .load(forceRefresh: true),
        ]);
        return task;
      },
    );
  }
}
