import 'admin_dashboard_todo_item.dart';
import 'admin_dashboard_todo_metrics.dart';

class AdminDashboardTodoPage {
  const AdminDashboardTodoPage({
    required this.items,
    required this.totalCount,
    required this.metrics,
  });

  final List<AdminDashboardTodoItem> items;
  final int totalCount;
  final AdminDashboardTodoMetrics metrics;

  static const empty = AdminDashboardTodoPage(
    items: [],
    totalCount: 0,
    metrics: AdminDashboardTodoMetrics.empty,
  );
}
