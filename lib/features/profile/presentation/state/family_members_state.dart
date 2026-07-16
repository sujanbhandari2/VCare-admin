import 'package:vcare_admin/features/profile/domain/entities/family_member.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class FamilyMembersState {
  const FamilyMembersState({
    this.operation = const OperationState<List<FamilyMember>>.idle(),
    this.creating = false,
  });

  final OperationState<List<FamilyMember>> operation;
  final bool creating;

  List<FamilyMember> get members => operation.data ?? const [];

  bool get fetching => operation.isLoading;

  bool get hasError => operation.hasError;

  String? get error => operation.errorMessage;

  FamilyMember? byId(String id) {
    for (final member in members) {
      if (member.id == id) {
        return member;
      }
    }
    return null;
  }

  FamilyMembersState loading() => FamilyMembersState(
        operation: OperationState.loading(data: members),
        creating: creating,
      );

  FamilyMembersState success(List<FamilyMember> members) => FamilyMembersState(
        operation: OperationState.success(members),
        creating: creating,
      );

  FamilyMembersState failure(String? message) => FamilyMembersState(
        operation: OperationState.failure(message, data: members),
        creating: creating,
      );

  FamilyMembersState withMembers(List<FamilyMember> members) => FamilyMembersState(
        operation: OperationState.success(members),
        creating: creating,
      );

  FamilyMembersState withCreating(bool creating) => FamilyMembersState(
        operation: operation,
        creating: creating,
      );
}
