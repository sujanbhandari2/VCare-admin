import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_utils.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class CareTeamState {
  const CareTeamState({
    this.operation = const OperationState<List<CareTeamMember>>.idle(),
    this.createOperation = const OperationState<CareTeamMember?>.idle(),
    this.updateOperation = const OperationState<CareTeamMember?>.idle(),
    this.deleteOperation = const OperationState<void>.idle(),
    this.memberOperation = const OperationState<CareTeamMember?>.idle(),
  });

  final OperationState<List<CareTeamMember>> operation;
  final OperationState<CareTeamMember?> createOperation;
  final OperationState<CareTeamMember?> updateOperation;
  final OperationState<void> deleteOperation;
  final OperationState<CareTeamMember?> memberOperation;

  List<CareTeamMember> get members => operation.data ?? const [];

  List<CareTeamMember> get listedTeam =>
      splitCareTeamMembers(members).listedTeam;

  List<CareTeamMember> get agentTeam => splitCareTeamMembers(members).agentTeam;

  bool get fetching => operation.isLoading;

  bool get fetchingMember => memberOperation.isLoading;

  bool get creating => createOperation.isLoading;

  bool get updating => updateOperation.isLoading;

  bool get deleting => deleteOperation.isLoading;

  bool get mutating => creating || updating || deleting;

  bool get hasError => operation.hasError;

  String? get error =>
      deleteOperation.errorMessage ??
      updateOperation.errorMessage ??
      createOperation.errorMessage ??
      memberOperation.errorMessage ??
      operation.errorMessage;

  String? get createError => createOperation.errorMessage;

  String? get updateError => updateOperation.errorMessage;

  String? get deleteError => deleteOperation.errorMessage;

  CareTeamMember? byId(String id) {
    for (final member in members) {
      if (member.id == id) {
        return member;
      }
    }
    final fetched = memberOperation.data;
    if (fetched != null && fetched.id == id) {
      return fetched;
    }
    return null;
  }

  CareTeamState loading() => CareTeamState(
        operation: OperationState.loading(data: members),
        createOperation: createOperation,
        updateOperation: updateOperation,
        deleteOperation: deleteOperation,
        memberOperation: memberOperation,
      );

  CareTeamState success(List<CareTeamMember> members) => CareTeamState(
        operation: OperationState.success(members),
        createOperation: createOperation,
        updateOperation: updateOperation,
        deleteOperation: deleteOperation,
        memberOperation: memberOperation,
      );

  CareTeamState failure(String? message) => CareTeamState(
        operation: OperationState.failure(message, data: members),
        createOperation: createOperation,
        updateOperation: updateOperation,
        deleteOperation: deleteOperation,
        memberOperation: memberOperation,
      );

  CareTeamState withMembers(List<CareTeamMember> members) => CareTeamState(
        operation: OperationState.success(members),
        createOperation: createOperation,
        updateOperation: updateOperation,
        deleteOperation: deleteOperation,
        memberOperation: memberOperation,
      );

  CareTeamState creatingInProgress() => CareTeamState(
        operation: operation,
        createOperation: OperationState.loading(data: createOperation.data),
        updateOperation: updateOperation,
        deleteOperation: deleteOperation,
        memberOperation: memberOperation,
      );

  CareTeamState createSuccess(CareTeamMember member) {
    final without = members.where((m) => m.id != member.id);
    return CareTeamState(
      operation: OperationState.success([...without, member]),
      createOperation: OperationState.success(member),
      updateOperation: updateOperation,
      deleteOperation: deleteOperation,
      memberOperation: memberOperation,
    );
  }

  CareTeamState createFailure(String? message) => CareTeamState(
        operation: operation,
        createOperation: OperationState.failure(message),
        updateOperation: updateOperation,
        deleteOperation: deleteOperation,
        memberOperation: memberOperation,
      );

  CareTeamState updatingInProgress() => CareTeamState(
        operation: operation,
        createOperation: createOperation,
        updateOperation: OperationState.loading(data: updateOperation.data),
        deleteOperation: deleteOperation,
        memberOperation: memberOperation,
      );

  CareTeamState updateSuccess(CareTeamMember member) {
    final next = [
      for (final existing in members)
        if (existing.id == member.id) member else existing,
    ];
    if (!next.any((m) => m.id == member.id)) {
      next.add(member);
    }
    return CareTeamState(
      operation: OperationState.success(next),
      createOperation: createOperation,
      updateOperation: OperationState.success(member),
      deleteOperation: deleteOperation,
      memberOperation: OperationState.success(member),
    );
  }

  CareTeamState updateFailure(String? message) => CareTeamState(
        operation: operation,
        createOperation: createOperation,
        updateOperation: OperationState.failure(message),
        deleteOperation: deleteOperation,
        memberOperation: memberOperation,
      );

  CareTeamState deletingInProgress() => CareTeamState(
        operation: operation,
        createOperation: createOperation,
        updateOperation: updateOperation,
        deleteOperation: const OperationState.loading(),
        memberOperation: memberOperation,
      );

  CareTeamState deleteSuccess(String id) => CareTeamState(
        operation: OperationState.success(
          members.where((member) => member.id != id).toList(),
        ),
        createOperation: createOperation,
        updateOperation: updateOperation,
        deleteOperation: const OperationState.success(null),
        memberOperation: memberOperation,
      );

  CareTeamState deleteFailure(String? message) => CareTeamState(
        operation: operation,
        createOperation: createOperation,
        updateOperation: updateOperation,
        deleteOperation: OperationState.failure(message),
        memberOperation: memberOperation,
      );

  CareTeamState memberLoading() => CareTeamState(
        operation: operation,
        createOperation: createOperation,
        updateOperation: updateOperation,
        deleteOperation: deleteOperation,
        memberOperation: OperationState.loading(data: memberOperation.data),
      );

  CareTeamState memberSuccess(CareTeamMember member) {
    final next = [
      for (final existing in members)
        if (existing.id == member.id) member else existing,
    ];
    if (!next.any((m) => m.id == member.id)) {
      next.add(member);
    }
    return CareTeamState(
      operation: OperationState.success(next),
      createOperation: createOperation,
      updateOperation: updateOperation,
      deleteOperation: deleteOperation,
      memberOperation: OperationState.success(member),
    );
  }

  CareTeamState memberFailure(String? message) => CareTeamState(
        operation: operation,
        createOperation: createOperation,
        updateOperation: updateOperation,
        deleteOperation: deleteOperation,
        memberOperation: OperationState.failure(message),
      );
}
