import 'package:vcare_admin/features/home/domain/entities/agent_stats.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AgentStatsState {
  const AgentStatsState({
    this.operation = const OperationState<AgentStats>.idle(),
    this.data,
  });

  final OperationState<AgentStats> operation;
  final AgentStats? data;

  bool get fetching => operation.isLoading;

  String? get error => operation.errorMessage;

  AgentStatsState loading() => AgentStatsState(
        operation: OperationState.loading(data: data),
        data: data,
      );

  AgentStatsState success(AgentStats stats) => AgentStatsState(
        operation: OperationState.success(stats),
        data: stats,
      );

  AgentStatsState failure(String? message) => AgentStatsState(
        operation: OperationState.failure(message, data: data),
        data: data,
      );
}
