import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_creation_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_details_step.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_note_step.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_shared_widgets.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_step_indicator.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_summary_step.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_cases_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_detail_state_provider.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

const _debounceMs = 300;

/// Case creation wizard scoped to a known client (skips client selection).
class ClientCaseCreateScreen extends ConsumerStatefulWidget {
  const ClientCaseCreateScreen({
    super.key,
    required this.clientId,
    this.prefillClient,
  });

  final String clientId;
  final CaseCreationClient? prefillClient;

  @override
  ConsumerState<ClientCaseCreateScreen> createState() =>
      _ClientCaseCreateScreenState();
}

class _ClientCaseCreateScreenState
    extends ConsumerState<ClientCaseCreateScreen> {
  final _noteController = TextEditingController();
  final _assigneeSearchController = TextEditingController();

  Timer? _assigneeDebounce;

  @override
  void initState() {
    super.initState();
    _noteController.addListener(_onNoteChanged);
    _assigneeSearchController.addListener(_onAssigneeQueryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final client = widget.prefillClient ?? _clientFromDetail();
      if (client == null) return;
      ref.read(caseCreationStateProvider.notifier).startForClient(client);
    });
  }

  CaseCreationClient? _clientFromDetail() {
    final detail = ref.read(clientDetailStateProvider(widget.clientId)).data;
    if (detail == null) return null;
    return caseCreationClientFromDetail(detail);
  }

  @override
  void dispose() {
    _assigneeDebounce?.cancel();
    _noteController
      ..removeListener(_onNoteChanged)
      ..dispose();
    _assigneeSearchController
      ..removeListener(_onAssigneeQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    ref.read(caseCreationStateProvider.notifier).setNote(_noteController.text);
  }

  void _onAssigneeQueryChanged() {
    _assigneeDebounce?.cancel();
    _assigneeDebounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      ref
          .read(caseCreationStateProvider.notifier)
          .searchAssignees(_assigneeSearchController.text);
    });
  }

  void _onBack() {
    final draft = ref.read(caseCreationStateProvider).draft;
    if (draft.showSummary || draft.currentStep > 1) {
      ref.read(caseCreationStateProvider.notifier).previousStep();
      return;
    }
    if (context.canPop()) {
      context.pop();
    }
  }

  void _confirmNote() {
    ref.read(caseCreationStateProvider.notifier).confirmNote();
  }

  void _goToSummary() {
    ref.read(caseCreationStateProvider.notifier).showSummary();
  }

  Future<void> _submit() async {
    final draft = ref.read(caseCreationStateProvider).draft;
    final clientName = draft.selectedClient?.fullName ?? 'client';

    await ref.read(caseCreationStateProvider.notifier).submit(
      onCompleted: (created, error) async {
        if (!mounted) return;
        if (created != null) {
          await ref
              .read(clientCasesStateProvider(widget.clientId).notifier)
              .refresh();
          if (!mounted) return;
          context.showVcareToast(
            title: 'Case for $clientName has been created successfully.',
            variant: VcareToastVariant.success,
          );
          if (context.canPop()) {
            context.pop();
          }
          return;
        }
        context.showVcareToast(
          title: error ?? 'Unable to create case.',
          variant: VcareToastVariant.destructive,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caseCreationStateProvider);
    final draft = state.draft;
    final client = draft.selectedClient;
    // Map wizard steps 1/2 (+ summary) onto a 2-label indicator.
    final indicatorStep = draft.showSummary ? 1 : draft.currentStep - 1;

    return Scaffold(
      body: Column(
        children: [
          VcareStickyPageHeader(
            title: 'New Case',
            showBack: true,
            onBack: _onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CaseCreateStepIndicator(
                    currentStep: indicatorStep.clamp(0, 1),
                    labels: const ['Note', 'Case Details'],
                  ),
                  if (client != null) ...[
                    const SizedBox(height: 16),
                    CaseCreateSelectedClientCard(client: client),
                  ],
                  const SizedBox(height: 24),
                  if (draft.showSummary)
                    CaseCreateSummaryStep(
                      draft: draft,
                      submitting: state.submitting,
                      onSubmit: _submit,
                    )
                  else if (draft.currentStep <= 1)
                    CaseCreateNoteStep(
                      state: state,
                      noteController: _noteController,
                      assigneeSearchController: _assigneeSearchController,
                      onConfirmNote: _confirmNote,
                      onSelectAssignee: (assignee) {
                        ref
                            .read(caseCreationStateProvider.notifier)
                            .selectAssignee(assignee);
                      },
                      onClearAssignee: () {
                        ref
                            .read(caseCreationStateProvider.notifier)
                            .selectAssignee(null);
                      },
                      onSearchAssigneesFocus: () {
                        if (state.assigneeResults.isEmpty &&
                            !state.searchingAssignees) {
                          ref
                              .read(caseCreationStateProvider.notifier)
                              .searchAssignees(
                                _assigneeSearchController.text,
                              );
                        }
                      },
                    )
                  else
                    CaseCreateDetailsStep(
                      draft: draft,
                      onSelectType: (type) {
                        ref
                            .read(caseCreationStateProvider.notifier)
                            .selectType(type);
                      },
                      onContinue: draft.canProceedFromDetails
                          ? _goToSummary
                          : null,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds a [CaseCreationClient] from a loaded [ClientDetail].
CaseCreationClient caseCreationClientFromDetail(ClientDetail detail) {
  final parts = detail.fullName.trim().split(RegExp(r'\s+'));
  final firstName = parts.isNotEmpty ? parts.first : '';
  final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
  return CaseCreationClient(
    id: detail.id,
    firstName: firstName,
    lastName: lastName,
    email: detail.email,
    phone: detail.phone,
  );
}
