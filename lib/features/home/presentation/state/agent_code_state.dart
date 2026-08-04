import 'package:vcare_admin/features/home/domain/entities/updated_agent_code.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AgentCodeState {
  const AgentCodeState({
    this.operation = const OperationState<UpdatedAgentCode?>.idle(),
  });

  final OperationState<UpdatedAgentCode?> operation;

  bool get updating => operation.isLoading;

  bool get hasError => operation.hasError;

  String? get error => operation.errorMessage;

  UpdatedAgentCode? get data => operation.data;

  AgentCodeState loading() => AgentCodeState(
        operation: OperationState.loading(data: data),
      );

  AgentCodeState success(UpdatedAgentCode result) => AgentCodeState(
        operation: OperationState.success(result),
      );

  AgentCodeState failure(String? message) => AgentCodeState(
        operation: OperationState.failure(message, data: data),
      );
}
