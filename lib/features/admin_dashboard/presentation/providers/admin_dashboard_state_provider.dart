import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/admin_dashboard/domain/repositories/admin_dashboard_repository.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_request.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_repository_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/state/admin_dashboard_state.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_formatters.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'admin_dashboard_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AdminDashboardStateNotifier extends _$AdminDashboardStateNotifier {
  @override
  AdminDashboardState build() => const AdminDashboardState();

  Future<void> load({
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    final userId = ref.read(adminAuthSessionProvider).user?.id;
    if (userId == null || userId.trim().isEmpty) {
      return;
    }

    if (ref.mounted) {
      state = state.loading();
    }

    final repository = ref.read(adminDashboardRepositoryProvider);

    await Future.wait([
      _loadFailedPayments(repository, forceRefresh, cancelToken),
      _loadTodoTasks(repository, forceRefresh, cancelToken),
      _loadOpenTasks(repository, userId, forceRefresh, cancelToken),
      _loadOpenCases(repository, userId, forceRefresh, cancelToken),
      _loadPendingMemberships(repository, forceRefresh, cancelToken),
      _loadPendingDocuments(repository, forceRefresh, cancelToken),
    ]);
  }

  Future<void> _loadFailedPayments(
    AdminDashboardRepository repository,
    bool forceRefresh,
    CancelToken? cancelToken,
  ) async {
    final response = await repository.fetchTodoList(
      const AdminDashboardTodoRequest(
        page: 1,
        limit: adminDashboardFailedPaymentsStatLimit,
        type: AdminDashboardTodoQueryType.paymentFailed,
      ),
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.copyWith(
            failedPaymentsOperation: OperationState.failure(
              error.userMessage,
              data: state.failedPaymentsOperation.data,
            ),
          );
        }
      },
      success: (page) {
        if (ref.mounted) {
          state = state.copyWith(
            failedPaymentsOperation: OperationState.success(page),
          );
        }
      },
    );
  }

  Future<void> _loadTodoTasks(
    AdminDashboardRepository repository,
    bool forceRefresh,
    CancelToken? cancelToken,
  ) async {
    final response = await repository.fetchTodoList(
      const AdminDashboardTodoRequest(
        page: 1,
        limit: adminDashboardWidgetPreviewLimit,
        type: AdminDashboardTodoQueryType.task,
      ),
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.copyWith(
            todoTasksOperation: OperationState.failure(
              error.userMessage,
              data: state.todoTasksOperation.data,
            ),
          );
        }
      },
      success: (page) {
        if (ref.mounted) {
          state = state.copyWith(
            todoTasksOperation: OperationState.success(page),
          );
        }
      },
    );
  }

  /// Reloads only the Failed Payments section, leaving the rest of the
  /// dashboard untouched so the other cards don't flash back to loading.
  Future<void> refreshFailedPayments() async {
    if (ref.mounted) {
      state = state.copyWith(
        failedPaymentsOperation: OperationState.loading(
          data: state.failedPaymentsOperation.data,
        ),
      );
    }

    await _loadFailedPayments(
      ref.read(adminDashboardRepositoryProvider),
      true,
      null,
    );
  }

  /// Reloads only the My Todo List section.
  Future<void> refreshTodoTasks() async {
    if (ref.mounted) {
      state = state.copyWith(
        todoTasksOperation: OperationState.loading(
          data: state.todoTasksOperation.data,
        ),
      );
    }

    await _loadTodoTasks(
      ref.read(adminDashboardRepositoryProvider),
      true,
      null,
    );
  }

  /// Reloads only the Pending Memberships count.
  Future<void> refreshPendingMemberships() async {
    if (ref.mounted) {
      state = state.copyWith(
        pendingMembershipsOperation: OperationState.loading(
          data: state.pendingMembershipsCount,
        ),
      );
    }

    await _loadPendingMemberships(
      ref.read(adminDashboardRepositoryProvider),
      true,
      null,
    );
  }

  Future<void> _loadOpenTasks(
    AdminDashboardRepository repository,
    String userId,
    bool forceRefresh,
    CancelToken? cancelToken,
  ) async {
    final response = await repository.fetchOpenTasksCount(
      userId: userId,
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = _copyWithOpenTasks(
            OperationState.failure(error.userMessage, data: state.openTasksCount),
          );
        }
      },
      success: (count) {
        if (ref.mounted) {
          state = _copyWithOpenTasks(OperationState.success(count));
        }
      },
    );
  }

  Future<void> _loadOpenCases(
    AdminDashboardRepository repository,
    String userId,
    bool forceRefresh,
    CancelToken? cancelToken,
  ) async {
    final response = await repository.fetchOpenCasesCount(
      userId: userId,
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = _copyWithOpenCases(
            OperationState.failure(error.userMessage, data: state.openCasesCount),
          );
        }
      },
      success: (count) {
        if (ref.mounted) {
          state = _copyWithOpenCases(OperationState.success(count));
        }
      },
    );
  }

  Future<void> _loadPendingMemberships(
    AdminDashboardRepository repository,
    bool forceRefresh,
    CancelToken? cancelToken,
  ) async {
    final response = await repository.fetchPendingMembershipsCount(
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = _copyWithPendingMemberships(
            OperationState.failure(
              error.userMessage,
              data: state.pendingMembershipsCount,
            ),
          );
        }
      },
      success: (count) {
        if (ref.mounted) {
          state = _copyWithPendingMemberships(OperationState.success(count));
        }
      },
    );
  }

  Future<void> _loadPendingDocuments(
    AdminDashboardRepository repository,
    bool forceRefresh,
    CancelToken? cancelToken,
  ) async {
    final response = await repository.fetchPendingDocumentsCount(
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = _copyWithPendingDocuments(
            OperationState.failure(
              error.userMessage,
              data: state.pendingDocumentsCount,
            ),
          );
        }
      },
      success: (count) {
        if (ref.mounted) {
          state = _copyWithPendingDocuments(OperationState.success(count));
        }
      },
    );
  }

  AdminDashboardState _copyWithOpenTasks(OperationState<int> operation) =>
      state.copyWith(openTasksOperation: operation);

  AdminDashboardState _copyWithOpenCases(OperationState<int> operation) =>
      state.copyWith(openCasesOperation: operation);

  AdminDashboardState _copyWithPendingMemberships(
    OperationState<int> operation,
  ) =>
      state.copyWith(pendingMembershipsOperation: operation);

  AdminDashboardState _copyWithPendingDocuments(
    OperationState<int> operation,
  ) =>
      state.copyWith(pendingDocumentsOperation: operation);
}
