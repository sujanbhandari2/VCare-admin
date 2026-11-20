import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_mutations.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_task_repository_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/state/my_tasks_preview_state.dart';
import 'package:vcare_admin/features/my_tasks/utils/my_task_formatters.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'my_tasks_preview_state_provider.g.dart';

@Riverpod(keepAlive: true)
class MyTasksPreviewStateNotifier extends _$MyTasksPreviewStateNotifier {
  @override
  MyTasksPreviewState build() => const MyTasksPreviewState();

  Future<void> load({bool forceRefresh = false}) async {
    final userId = ref.read(adminAuthSessionProvider).user?.id.trim();
    if (userId == null || userId.isEmpty) return;

    if (ref.mounted) {
      state = state.loadingState();
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .fetchTasks(
          MyTaskListRequest(
            page: 1,
            limit: myTasksWidgetPreviewLimit,
            assignedToUser: userId,
            type: MyTaskListType.open,
            sortBy: 'createdAt',
            sortOrder: 'desc',
          ),
          forceRefresh: forceRefresh,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
      },
      success: (page) {
        if (ref.mounted) {
          state = state.success(page.items, page.metrics);
        }
      },
    );
  }

  Future<void> refresh() => load(forceRefresh: true);

  Future<bool> completeTask({
    required String taskId,
    void Function(String? error)? onError,
  }) async {
    if (state.mutatingTaskId != null) return false;
    if (ref.mounted) {
      state = state.copyWith(mutatingTaskId: taskId);
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .updateTask(
          taskId: taskId,
          request: const MyTaskUpdateRequest(status: MyTaskStatus.done),
        );

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (_) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        await Future.wait([
          refresh(),
          ref
              .read(adminDashboardStateProvider.notifier)
              .load(forceRefresh: true),
        ]);
        return true;
      },
    );
  }
}
