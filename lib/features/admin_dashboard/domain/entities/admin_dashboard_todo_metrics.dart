class AdminDashboardTodoMetrics {
  const AdminDashboardTodoMetrics({
    this.failedPayments = 0,
    this.overdue = 0,
    this.dueSoon = 0,
  });

  final int failedPayments;
  final int overdue;
  final int dueSoon;

  static const empty = AdminDashboardTodoMetrics();
}
