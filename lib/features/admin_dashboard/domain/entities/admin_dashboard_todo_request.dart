/// Query filter for `GET /admin/todo-list`.
enum AdminDashboardTodoQueryType {
  paymentFailed('PAYMENT_FAILED'),
  task('TASK'),
  taskOverdue('TASK_OVERDUE'),
  taskDueSoon('TASK_DUE_SOON');

  const AdminDashboardTodoQueryType(this.apiValue);

  final String apiValue;
}

class AdminDashboardTodoRequest {
  const AdminDashboardTodoRequest({
    this.page = 1,
    this.limit = 20,
    this.type,
  });

  final int page;
  final int limit;
  final AdminDashboardTodoQueryType? type;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (type != null) {
      params['type'] = type!.apiValue;
    }
    return params;
  }

  AdminDashboardTodoRequest copyWith({
    int? page,
    int? limit,
    AdminDashboardTodoQueryType? type,
  }) {
    return AdminDashboardTodoRequest(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      type: type ?? this.type,
    );
  }
}
