import 'package:intl/intl.dart';

import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_metrics.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_page.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AdminDashboardState {
  const AdminDashboardState({
    this.failedPaymentsOperation =
        const OperationState<AdminDashboardTodoPage>.idle(),
    this.todoTasksOperation =
        const OperationState<AdminDashboardTodoPage>.idle(),
    this.openTasksOperation = const OperationState<int>.idle(),
    this.openCasesOperation = const OperationState<int>.idle(),
    this.pendingMembershipsOperation = const OperationState<int>.idle(),
    this.pendingDocumentsOperation = const OperationState<int>.idle(),
  });

  final OperationState<AdminDashboardTodoPage> failedPaymentsOperation;
  final OperationState<AdminDashboardTodoPage> todoTasksOperation;
  final OperationState<int> openTasksOperation;
  final OperationState<int> openCasesOperation;
  final OperationState<int> pendingMembershipsOperation;
  final OperationState<int> pendingDocumentsOperation;

  bool get isAnyLoading =>
      failedPaymentsOperation.isLoading ||
      todoTasksOperation.isLoading ||
      openTasksOperation.isLoading ||
      openCasesOperation.isLoading ||
      pendingMembershipsOperation.isLoading ||
      pendingDocumentsOperation.isLoading;

  /// True when every dashboard fetch failed and there is nothing useful to show.
  bool get isInitialLoadFailure {
    if (isAnyLoading) return false;

    final paymentsFailed =
        failedPaymentsOperation.hasError && failedPaymentRows.isEmpty;
    final todosFailed = todoTasksOperation.hasError && todoRows.isEmpty;
    final openTasksFailed = openTasksOperation.hasError;
    final openCasesFailed = openCasesOperation.hasError;
    final documentsFailed = pendingDocumentsOperation.hasError;

    return paymentsFailed &&
        todosFailed &&
        openTasksFailed &&
        openCasesFailed &&
        documentsFailed;
  }

  String? get initialLoadErrorMessage =>
      failedPaymentsOperation.errorMessage ??
      todoTasksOperation.errorMessage ??
      openTasksOperation.errorMessage ??
      openCasesOperation.errorMessage ??
      pendingDocumentsOperation.errorMessage ??
      pendingMembershipsOperation.errorMessage;

  List<AdminDashboardFailedPaymentTodoItem> get failedPaymentRows {
    final page = failedPaymentsOperation.data;
    if (page == null) return const [];
    return page.items.whereType<AdminDashboardFailedPaymentTodoItem>().toList(
      growable: false,
    );
  }

  List<AdminDashboardTaskTodoItem> get todoRows {
    final page = todoTasksOperation.data;
    if (page == null) return const [];
    return page.items.whereType<AdminDashboardTaskTodoItem>().toList(
      growable: false,
    );
  }

  AdminDashboardTodoMetrics get failedPaymentMetrics =>
      failedPaymentsOperation.data?.metrics ?? AdminDashboardTodoMetrics.empty;

  AdminDashboardTodoMetrics get todoMetrics =>
      todoTasksOperation.data?.metrics ?? AdminDashboardTodoMetrics.empty;

  int get overdueCount => todoMetrics.overdue;

  int get failedPaymentsCount => failedPaymentMetrics.failedPayments;

  double get atRiskAmount {
    return failedPaymentRows.fold(0, (sum, item) {
      final amount = double.tryParse(item.details.amount ?? '');
      return sum + (amount ?? 0);
    });
  }

  String get atRiskCurrency {
    for (final item in failedPaymentRows) {
      final currency = item.details.currency?.trim();
      if (currency != null && currency.isNotEmpty) return currency;
    }
    return 'USD';
  }

  int get atRiskClientCount {
    final clientIds = <String>{};
    for (final item in failedPaymentRows) {
      final clientId = item.details.relatedId?.trim();
      if (clientId != null && clientId.isNotEmpty) {
        clientIds.add(clientId);
      }
    }
    return clientIds.length;
  }

  String? get atRiskCaption {
    if (atRiskAmount == 0) return null;
    if (atRiskClientCount == 1) return 'Across 1 client';
    if (atRiskClientCount > 1) {
      return 'Across ${_formatCount(atRiskClientCount)} clients';
    }
    final failedCount = failedPaymentsOperation.data?.totalCount ?? 0;
    if (failedCount == 1) return '1 failed payment';
    if (failedCount > 1) {
      return '${_formatCount(failedCount)} failed payments';
    }
    return 'Failed payments need attention';
  }

  int get openTasksCount => openTasksOperation.data ?? 0;
  int get openCasesCount => openCasesOperation.data ?? 0;
  int get pendingMembershipsCount => pendingMembershipsOperation.data ?? 0;
  int get pendingDocumentsCount => pendingDocumentsOperation.data ?? 0;

  AdminDashboardState copyWith({
    OperationState<AdminDashboardTodoPage>? failedPaymentsOperation,
    OperationState<AdminDashboardTodoPage>? todoTasksOperation,
    OperationState<int>? openTasksOperation,
    OperationState<int>? openCasesOperation,
    OperationState<int>? pendingMembershipsOperation,
    OperationState<int>? pendingDocumentsOperation,
  }) {
    return AdminDashboardState(
      failedPaymentsOperation:
          failedPaymentsOperation ?? this.failedPaymentsOperation,
      todoTasksOperation: todoTasksOperation ?? this.todoTasksOperation,
      openTasksOperation: openTasksOperation ?? this.openTasksOperation,
      openCasesOperation: openCasesOperation ?? this.openCasesOperation,
      pendingMembershipsOperation:
          pendingMembershipsOperation ?? this.pendingMembershipsOperation,
      pendingDocumentsOperation:
          pendingDocumentsOperation ?? this.pendingDocumentsOperation,
    );
  }

  AdminDashboardState loading() {
    return AdminDashboardState(
      failedPaymentsOperation: OperationState.loading(
        data: failedPaymentsOperation.data,
      ),
      todoTasksOperation: OperationState.loading(data: todoTasksOperation.data),
      openTasksOperation: OperationState.loading(data: openTasksOperation.data),
      openCasesOperation: OperationState.loading(data: openCasesOperation.data),
      pendingMembershipsOperation: OperationState.loading(
        data: pendingMembershipsOperation.data,
      ),
      pendingDocumentsOperation: OperationState.loading(
        data: pendingDocumentsOperation.data,
      ),
    );
  }

  static String _formatCount(int value) {
    return NumberFormat.decimalPattern().format(value);
  }
}
