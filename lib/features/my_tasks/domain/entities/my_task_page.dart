import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_metrics.dart';

/// Paginated task list result with optional tab metrics.
class MyTaskPage {
  const MyTaskPage({
    required this.items,
    required this.totalCount,
    this.metrics = MyTaskMetrics.empty,
  });

  final List<MyTask> items;
  final int totalCount;
  final MyTaskMetrics metrics;
}
