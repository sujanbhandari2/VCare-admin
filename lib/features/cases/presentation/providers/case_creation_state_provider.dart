import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_creation_state.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'case_creation_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CaseCreationStateNotifier extends _$CaseCreationStateNotifier {
  static const int _stepCount = 3;
  static const int _clientSearchLimit = 10;

  int _clientSearchGeneration = 0;
  int _assigneeSearchGeneration = 0;

  @override
  CaseCreationState build() => const CaseCreationState();

  void reset() {
    if (!ref.mounted) return;
    state = const CaseCreationState();
  }

  /// Starts the wizard with a fixed client (skips the client selection step).
  void startForClient(CaseCreationClient client) {
    if (!ref.mounted) return;
    state = CaseCreationState(
      draft: CaseCreationDraft(
        selectedClient: client,
        clientLocked: true,
        currentStep: 1,
      ),
    );
    // Prefetch assignees so the note step shows results without focusing search.
    searchAssignees('');
  }

  void selectClient(CaseCreationClient client) {
    if (!ref.mounted) return;
    final advancingFromClientStep = state.draft.currentStep == 0;
    state = state.withDraft(
      state.draft.copyWith(
        selectedClient: client,
        currentStep: advancingFromClientStep ? 1 : state.draft.currentStep,
      ),
    );
    if (advancingFromClientStep) {
      searchAssignees('');
    }
  }

  void clearClient() {
    if (!ref.mounted) return;
    if (state.draft.clientLocked) return;
    state = state.withDraft(
      state.draft.copyWith(
        clearClient: true,
        noteConfirmed: false,
        clearAssignee: true,
        clearType: true,
        showSummary: false,
        currentStep: 0,
      ),
    );
  }

  void setNote(String note) {
    if (!ref.mounted) return;
    state = state.withDraft(
      state.draft.copyWith(
        initialNote: note,
        noteConfirmed: false,
      ),
    );
  }

  void confirmNote() {
    if (!ref.mounted) return;
    state = state.withDraft(
      state.draft.copyWith(
        noteConfirmed: true,
        currentStep: 2,
      ),
    );
  }

  void selectAssignee(CaseAssignee? assignee) {
    if (!ref.mounted) return;
    state = state.withDraft(
      assignee == null
          ? state.draft.copyWith(clearAssignee: true)
          : state.draft.copyWith(selectedAssignee: assignee),
    );
  }

  void selectType(String type) {
    if (!ref.mounted) return;
    state = state.withDraft(
      state.draft.copyWith(selectedType: type),
    );
  }

  void nextStep() {
    if (!ref.mounted) return;
    final draft = state.draft;
    final step = draft.currentStep;

    if (step == 0 && !draft.canProceedFromClient) return;
    if (step == 1 && !draft.canProceedFromNote) {
      state = state.withDraft(
        draft.copyWith(noteConfirmed: true, currentStep: 2),
      );
      return;
    }
    if (step == 2 && !draft.canProceedFromDetails) return;

    if (step >= _stepCount - 1) {
      showSummary();
      return;
    }

    state = state.withDraft(draft.copyWith(currentStep: step + 1));
    if (step == 0) {
      searchAssignees('');
    }
  }

  void previousStep() {
    if (!ref.mounted) return;
    final draft = state.draft;
    if (draft.showSummary) {
      state = state.withDraft(draft.copyWith(showSummary: false));
      return;
    }
    if (draft.currentStep <= 0) return;
    final nextStep = draft.currentStep - 1;
    state = state.withDraft(
      draft.copyWith(currentStep: nextStep),
    );
    if (nextStep == 1) {
      searchAssignees('');
    }
  }

  void showSummary() {
    if (!ref.mounted) return;
    final draft = state.draft;
    if (!draft.canProceedFromClient || !draft.canProceedFromDetails) return;
    state = state.withDraft(
      draft.copyWith(
        noteConfirmed: true,
        showSummary: true,
        currentStep: _stepCount - 1,
      ),
    );
  }

  Future<void> searchClients(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final generation = ++_clientSearchGeneration;
    final trimmed = query.trim();

    if (ref.mounted) {
      state = state.clientSearchLoading();
    }

    final response = await ref.read(clientRepositoryProvider).fetchClients(
      ClientsListRequest(
        page: 1,
        limit: _clientSearchLimit,
        search: trimmed.isEmpty ? null : trimmed,
        clientType: ClientListType.individual,
      ),
      cancelToken: cancelToken,
      forceRefresh: true,
    );

    if (!ref.mounted || generation != _clientSearchGeneration) return;

    response.when(
      failure: (error) {
        if (ref.mounted && generation == _clientSearchGeneration) {
          state = state.clientSearchFailure(error.userMessage);
        }
      },
      success: (result) {
        if (ref.mounted && generation == _clientSearchGeneration) {
          state = state.clientSearchSuccess(
            result.items.map(_mapClientListItem).toList(),
          );
        }
      },
    );
  }

  Future<void> searchAssignees(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final generation = ++_assigneeSearchGeneration;
    final trimmed = query.trim();

    if (ref.mounted) {
      state = state.assigneeSearchLoading();
    }

    final response = await ref.read(caseRepositoryProvider).fetchAssignees(
      search: trimmed.isEmpty ? null : trimmed,
      cancelToken: cancelToken,
      forceRefresh: true,
    );

    if (!ref.mounted || generation != _assigneeSearchGeneration) return;

    response.when(
      failure: (error) {
        if (ref.mounted && generation == _assigneeSearchGeneration) {
          state = state.assigneeSearchFailure(error.userMessage);
        }
      },
      success: (assignees) {
        if (ref.mounted && generation == _assigneeSearchGeneration) {
          state = state.assigneeSearchSuccess(assignees);
        }
      },
    );
  }

  Future<void> submit({
    CancelToken? cancelToken,
    void Function(ReferralCase? created, String? error)? onCompleted,
  }) async {
    final draft = state.draft;
    final client = draft.selectedClient;
    if (client == null || state.submitting) return;
    if (!draft.canProceedFromDetails) return;

    if (ref.mounted) {
      state = state.submitLoading();
    }

    final trimmedNote = draft.initialNote.trim();
    final body = CreateCaseBody(
      clientId: client.id,
      status: CaseStatus.newCase.apiValue,
      type: draft.selectedType != null
          ? mapCaseTypeLabelToApi(draft.selectedType!)
          : null,
      assignedTo: draft.selectedAssignee?.id,
      notes: trimmedNote.isEmpty
          ? null
          : [
              CreateCaseNoteBody(
                note: trimmedNote,
                accessType: defaultNoteAccessType,
              ),
            ],
    );

    final response = await ref.read(caseRepositoryProvider).createCase(
      body,
      cancelToken: cancelToken,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.submitFailure(error.userMessage);
        }
        onCompleted?.call(null, error.userMessage);
      },
      success: (created) {
        if (ref.mounted) {
          state = state.submitSuccess(created);
        }
        onCompleted?.call(created, null);
      },
    );
  }

  CaseCreationClient _mapClientListItem(ClientListItem item) {
    final parts = item.fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return CaseCreationClient(
      id: item.id,
      firstName: firstName,
      lastName: lastName,
      email: item.email,
      phone: item.phone,
    );
  }
}
