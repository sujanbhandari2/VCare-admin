import 'package:vcare_admin/shared/state/operation_state.dart';
import '../../domain/entities/ava_message.dart';

class AvaState {
  const AvaState({
    this.messages = const [],
    this.operation = const OperationState<void>.idle(),
    this.editingId,
  });

  final List<AvaMessage> messages;
  final OperationState<void> operation;
  final String? editingId;

  bool get isLoading => operation.isLoading;
  String? get errorMessage => operation.errorMessage;

  AvaState copyWith({
    List<AvaMessage>? messages,
    OperationState<void>? operation,
    String? editingId,
  }) {
    return AvaState(
      messages: messages ?? this.messages,
      operation: operation ?? this.operation,
      editingId: editingId ?? this.editingId,
    );
  }

  AvaState loading() => copyWith(operation: const OperationState.loading());
  AvaState success({List<AvaMessage>? messages}) => copyWith(
    messages: messages ?? this.messages,
    operation: const OperationState.success(null),
  );
  AvaState failure(String? message) =>
      copyWith(operation: OperationState.failure(message));
}
