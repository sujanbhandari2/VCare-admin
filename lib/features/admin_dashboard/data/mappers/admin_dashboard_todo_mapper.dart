import 'package:vcare_admin/features/admin_dashboard/data/models/admin_dashboard_todo_item_model.dart';
import 'package:vcare_admin/features/admin_dashboard/data/models/admin_dashboard_todo_metrics_model.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_metrics.dart';

extension AdminDashboardTodoMetricsModelMapper
    on AdminDashboardTodoMetricsModel {
  AdminDashboardTodoMetrics toEntity() {
    return AdminDashboardTodoMetrics(
      failedPayments: failedPayments,
      overdue: overdue,
      dueSoon: dueSoon,
    );
  }
}

extension AdminDashboardTodoItemModelMapper on AdminDashboardTodoItemModel {
  AdminDashboardTodoItem? toEntity() {
    final resource = AdminDashboardTodoResource(
      type: this.resource.type,
      id: this.resource.id,
    );

    // API timestamps are UTC; due/overdue labels compare against the device's
    // calendar day, so normalize to local time like the web client does.
    final occurred = DateTime.tryParse(occurredAt)?.toLocal() ?? DateTime.now();

    if (isPaymentFailed && details != null) {
      return AdminDashboardFailedPaymentTodoItem(
        id: id,
        title: title,
        description: description,
        occurredAt: occurred,
        resource: resource,
        details: AdminDashboardPaymentDetails(
          name: details!.name,
          amount: details!.amount,
          currency: details!.currency,
          code: details!.code,
          relatedId: details!.relatedId,
          membershipName: details!.membershipName,
          billingStartDate: details!.billingStartDate,
          billingEndDate: details!.billingEndDate,
          failureReason: details!.failureReason,
          failureMessage: details!.failureMessage,
          failureActionMessage: details!.failureActionMessage,
        ),
      );
    }

    if (isTaskOverdue || isTaskDueSoon) {
      return AdminDashboardTaskTodoItem(
        id: id,
        title: title,
        description: description,
        occurredAt: occurred,
        resource: resource,
        itemType: isTaskOverdue
            ? AdminDashboardTodoItemType.taskOverdue
            : AdminDashboardTodoItemType.taskDueSoon,
        priority: _mapPriority(priority),
        status: _mapStatus(status),
        dueDate: DateTime.tryParse(dueDate ?? '')?.toLocal() ?? occurred,
        client: client == null
            ? null
            : AdminDashboardTodoClientPreview(
                id: client!.id,
                name: client!.name,
              ),
      );
    }

    return null;
  }

  AdminDashboardTaskPriority _mapPriority(String? value) {
    switch (value?.toUpperCase()) {
      case 'URGENT':
        return AdminDashboardTaskPriority.urgent;
      case 'HIGH':
        return AdminDashboardTaskPriority.high;
      case 'MEDIUM':
        return AdminDashboardTaskPriority.medium;
      case 'LOW':
      default:
        return AdminDashboardTaskPriority.low;
    }
  }

  AdminDashboardTaskStatus _mapStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'IN_PROGRESS':
        return AdminDashboardTaskStatus.inProgress;
      case 'DONE':
      case 'COMPLETED':
        return AdminDashboardTaskStatus.completed;
      case 'CANCELLED':
        return AdminDashboardTaskStatus.cancelled;
      case 'NEW':
      default:
        return AdminDashboardTaskStatus.newTask;
    }
  }
}
