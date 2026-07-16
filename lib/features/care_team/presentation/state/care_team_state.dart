import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class CareTeamState {
  const CareTeamState({
    this.operation = const OperationState<List<CareTeamMember>>.idle(),
    this.createOperation = const OperationState<CareTeamMember?>.idle(),
  });

  final OperationState<List<CareTeamMember>> operation;
  final OperationState<CareTeamMember?> createOperation;

  List<CareTeamMember> get members => operation.data ?? const [];

  bool get fetching => operation.isLoading;

  bool get creating => createOperation.isLoading;

  bool get hasError => operation.hasError;

  String? get error =>
      createOperation.errorMessage ?? operation.errorMessage;

  String? get createError => createOperation.errorMessage;

  CareTeamMember? byId(String id) {
    for (final member in members) {
      if (member.id == id) {
        return member;
      }
    }
    return null;
  }

  CareTeamState loading() => CareTeamState(
        operation: OperationState.loading(data: members),
        createOperation: createOperation,
      );

  CareTeamState success(List<CareTeamMember> members) => CareTeamState(
        operation: OperationState.success(members),
        createOperation: createOperation,
      );

  CareTeamState failure(String? message) => CareTeamState(
        operation: OperationState.failure(message, data: members),
        createOperation: createOperation,
      );

  CareTeamState withMembers(List<CareTeamMember> members) => CareTeamState(
        operation: OperationState.success(members),
        createOperation: createOperation,
      );

  CareTeamState creatingInProgress() => CareTeamState(
        operation: operation,
        createOperation: OperationState.loading(data: createOperation.data),
      );

  CareTeamState createSuccess(CareTeamMember member) => CareTeamState(
        operation: OperationState.success([...members, member]),
        createOperation: OperationState.success(member),
      );

  CareTeamState createFailure(String? message) => CareTeamState(
        operation: operation,
        createOperation: OperationState.failure(message),
      );
}
