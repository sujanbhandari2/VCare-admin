import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// Wizard + submit state for creating a referral case.
class CaseCreationState {
  const CaseCreationState({
    this.draft = const CaseCreationDraft(),
    this.submitOperation = const OperationState<ReferralCase?>.idle(),
    this.clientSearchOperation =
        const OperationState<List<CaseCreationClient>>.idle(),
    this.assigneeSearchOperation =
        const OperationState<List<CaseAssignee>>.idle(),
  });

  final CaseCreationDraft draft;
  final OperationState<ReferralCase?> submitOperation;
  final OperationState<List<CaseCreationClient>> clientSearchOperation;
  final OperationState<List<CaseAssignee>> assigneeSearchOperation;

  bool get submitting => submitOperation.isLoading;

  bool get searchingClients => clientSearchOperation.isLoading;

  bool get searchingAssignees => assigneeSearchOperation.isLoading;

  List<CaseCreationClient> get clientResults =>
      clientSearchOperation.data ?? const [];

  List<CaseAssignee> get assigneeResults =>
      assigneeSearchOperation.data ?? const [];

  ReferralCase? get createdCase => submitOperation.data;

  String? get error =>
      submitOperation.errorMessage ??
      clientSearchOperation.errorMessage ??
      assigneeSearchOperation.errorMessage;

  CaseCreationState copyWith({
    CaseCreationDraft? draft,
    OperationState<ReferralCase?>? submitOperation,
    OperationState<List<CaseCreationClient>>? clientSearchOperation,
    OperationState<List<CaseAssignee>>? assigneeSearchOperation,
  }) {
    return CaseCreationState(
      draft: draft ?? this.draft,
      submitOperation: submitOperation ?? this.submitOperation,
      clientSearchOperation:
          clientSearchOperation ?? this.clientSearchOperation,
      assigneeSearchOperation:
          assigneeSearchOperation ?? this.assigneeSearchOperation,
    );
  }

  CaseCreationState withDraft(CaseCreationDraft draft) =>
      copyWith(draft: draft);

  CaseCreationState submitLoading() => copyWith(
    submitOperation: OperationState<ReferralCase?>.loading(
      data: submitOperation.data,
    ),
  );

  CaseCreationState submitSuccess(ReferralCase? created) => copyWith(
    submitOperation: OperationState<ReferralCase?>.success(created),
  );

  CaseCreationState submitFailure(String? message) => copyWith(
    submitOperation: OperationState<ReferralCase?>.failure(
      message,
      data: submitOperation.data,
    ),
  );

  CaseCreationState clientSearchLoading() => copyWith(
    clientSearchOperation: OperationState<List<CaseCreationClient>>.loading(
      data: clientSearchOperation.data,
    ),
  );

  CaseCreationState clientSearchSuccess(List<CaseCreationClient> results) =>
      copyWith(
        clientSearchOperation:
            OperationState<List<CaseCreationClient>>.success(results),
      );

  CaseCreationState clientSearchFailure(String? message) => copyWith(
    clientSearchOperation: OperationState<List<CaseCreationClient>>.failure(
      message,
      data: clientSearchOperation.data,
    ),
  );

  CaseCreationState assigneeSearchLoading() => copyWith(
    assigneeSearchOperation: OperationState<List<CaseAssignee>>.loading(
      data: assigneeSearchOperation.data,
    ),
  );

  CaseCreationState assigneeSearchSuccess(List<CaseAssignee> results) =>
      copyWith(
        assigneeSearchOperation: OperationState<List<CaseAssignee>>.success(
          results,
        ),
      );

  CaseCreationState assigneeSearchFailure(String? message) => copyWith(
    assigneeSearchOperation: OperationState<List<CaseAssignee>>.failure(
      message,
      data: assigneeSearchOperation.data,
    ),
  );
}
