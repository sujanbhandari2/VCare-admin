import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// Assignee search results for pickers outside the creation wizard.
class CaseAssigneesStateData {
  const CaseAssigneesStateData({
    this.searchOperation = const OperationState<List<CaseAssignee>>.idle(),
  });

  final OperationState<List<CaseAssignee>> searchOperation;

  List<CaseAssignee> get assignees => searchOperation.data ?? const [];

  bool get searching => searchOperation.isLoading;

  String? get error => searchOperation.errorMessage;

  CaseAssigneesStateData loading() => CaseAssigneesStateData(
    searchOperation: OperationState<List<CaseAssignee>>.loading(
      data: assignees,
    ),
  );

  CaseAssigneesStateData success(List<CaseAssignee> results) =>
      CaseAssigneesStateData(
        searchOperation: OperationState<List<CaseAssignee>>.success(results),
      );

  CaseAssigneesStateData failure(String? message) => CaseAssigneesStateData(
    searchOperation: OperationState<List<CaseAssignee>>.failure(
      message,
      data: assignees,
    ),
  );
}
