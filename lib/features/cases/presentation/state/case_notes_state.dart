import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// Notes list + mutation state for a single case.
class CaseNotesStateData {
  const CaseNotesStateData({
    this.fetchOperation = const OperationState<List<CaseNote>>.idle(),
    this.mutationOperation = const OperationState<void>.idle(),
    this.tagUsersOperation =
        const OperationState<List<CaseNoteTagUser>>.idle(),
    this.summarizeOperation = const OperationState<String>.idle(),
    this.accessTogglingNoteId,
  });

  final OperationState<List<CaseNote>> fetchOperation;
  final OperationState<void> mutationOperation;
  final OperationState<List<CaseNoteTagUser>> tagUsersOperation;
  final OperationState<String> summarizeOperation;

  /// Note whose visibility is currently being switched, for a per-row spinner.
  final String? accessTogglingNoteId;

  List<CaseNote> get notes => fetchOperation.data ?? const [];

  List<CaseNoteTagUser> get tagUsers => tagUsersOperation.data ?? const [];

  bool get fetching => fetchOperation.isLoading;

  bool get mutating => mutationOperation.isLoading;

  bool get searchingTagUsers => tagUsersOperation.isLoading;

  bool get summarizing => summarizeOperation.isLoading;

  String? get summaryText => summarizeOperation.data;

  String? get summarizeError => summarizeOperation.errorMessage;

  bool get isInitialLoading => fetchOperation.isLoading && notes.isEmpty;

  bool get isRefreshing => fetchOperation.isLoading && notes.isNotEmpty;

  String? get error =>
      mutationOperation.errorMessage ??
      summarizeOperation.errorMessage ??
      fetchOperation.errorMessage;

  CaseNotesStateData copyWith({
    OperationState<List<CaseNote>>? fetchOperation,
    OperationState<void>? mutationOperation,
    OperationState<List<CaseNoteTagUser>>? tagUsersOperation,
    OperationState<String>? summarizeOperation,
    String? accessTogglingNoteId,
    bool clearAccessTogglingNoteId = false,
  }) {
    return CaseNotesStateData(
      fetchOperation: fetchOperation ?? this.fetchOperation,
      mutationOperation: mutationOperation ?? this.mutationOperation,
      tagUsersOperation: tagUsersOperation ?? this.tagUsersOperation,
      summarizeOperation: summarizeOperation ?? this.summarizeOperation,
      accessTogglingNoteId: clearAccessTogglingNoteId
          ? null
          : (accessTogglingNoteId ?? this.accessTogglingNoteId),
    );
  }

  CaseNotesStateData loading() => copyWith(
    fetchOperation: OperationState<List<CaseNote>>.loading(data: notes),
  );

  CaseNotesStateData success(List<CaseNote> notes) => copyWith(
    fetchOperation: OperationState<List<CaseNote>>.success(notes),
  );

  CaseNotesStateData failure(String? message) => copyWith(
    fetchOperation: OperationState<List<CaseNote>>.failure(
      message,
      data: notes,
    ),
  );

  CaseNotesStateData mutationLoading() =>
      copyWith(mutationOperation: const OperationState<void>.loading());

  CaseNotesStateData mutationIdle() =>
      copyWith(mutationOperation: const OperationState<void>.idle());

  CaseNotesStateData mutationFailure(String? message) => copyWith(
    mutationOperation: OperationState<void>.failure(message),
  );

  CaseNotesStateData summarizeLoading() => copyWith(
    summarizeOperation: OperationState<String>.loading(data: summaryText),
  );

  CaseNotesStateData summarizeSuccess(String summary) => copyWith(
    summarizeOperation: OperationState<String>.success(summary),
  );

  CaseNotesStateData summarizeFailure(String? message) => copyWith(
    summarizeOperation: OperationState<String>.failure(
      message,
      data: summaryText,
    ),
  );

  CaseNotesStateData summarizeIdle() =>
      copyWith(summarizeOperation: const OperationState<String>.idle());
}
