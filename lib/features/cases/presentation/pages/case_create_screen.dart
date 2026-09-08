import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_creation_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_creation_state.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_details_step.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_note_step.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_shared_widgets.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_step_indicator.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_summary_step.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

const _debounceMs = 300;

class CaseCreateScreen extends ConsumerStatefulWidget {
  const CaseCreateScreen({super.key});

  @override
  ConsumerState<CaseCreateScreen> createState() => _CaseCreateScreenState();
}

class _CaseCreateScreenState extends ConsumerState<CaseCreateScreen> {
  final _clientSearchController = TextEditingController();
  final _noteController = TextEditingController();
  final _assigneeSearchController = TextEditingController();

  Timer? _clientDebounce;
  Timer? _assigneeDebounce;

  @override
  void initState() {
    super.initState();
    _clientSearchController.addListener(_onClientQueryChanged);
    _noteController.addListener(_onNoteChanged);
    _assigneeSearchController.addListener(_onAssigneeQueryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(caseCreationStateProvider.notifier);
      notifier.reset();
      notifier.searchClients('');
    });
  }

  @override
  void dispose() {
    _clientDebounce?.cancel();
    _assigneeDebounce?.cancel();
    _clientSearchController
      ..removeListener(_onClientQueryChanged)
      ..dispose();
    _noteController
      ..removeListener(_onNoteChanged)
      ..dispose();
    _assigneeSearchController
      ..removeListener(_onAssigneeQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _onClientQueryChanged() {
    _clientDebounce?.cancel();
    _clientDebounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      ref
          .read(caseCreationStateProvider.notifier)
          .searchClients(_clientSearchController.text);
    });
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
    if (draft.showSummary || draft.currentStep > 0) {
      ref.read(caseCreationStateProvider.notifier).previousStep();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.cases);
    }
  }

  void _clearClient() {
    _clientSearchController.clear();
    _noteController.clear();
    _assigneeSearchController.clear();
    ref.read(caseCreationStateProvider.notifier).clearClient();
    ref.read(caseCreationStateProvider.notifier).searchClients('');
  }

  void _selectClient(CaseCreationClient client) {
    _clientSearchController.clear();
    ref.read(caseCreationStateProvider.notifier).selectClient(client);
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
      onCompleted: (created, error) {
        if (!mounted) return;
        if (created != null) {
          context.showVcareToast(
            title: 'Case for $clientName has been created successfully.',
            variant: VcareToastVariant.success,
          );
          context.goNamed(AppRouter.cases.toPathName);
          return;
        }
        context.showVcareToast(
          title: error ?? 'Unable to create case.',
          variant: VcareToastVariant.destructive,
        );
      },
    );
  }

  void _continueFromClient() {
    ref.read(caseCreationStateProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caseCreationStateProvider);
    final draft = state.draft;
    final step = draft.showSummary ? 2 : draft.currentStep;

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
                  CaseCreateStepIndicator(currentStep: step),
                  const SizedBox(height: 24),
                  if (draft.showSummary)
                    CaseCreateSummaryStep(
                      draft: draft,
                      submitting: state.submitting,
                      onSubmit: _submit,
                    )
                  else if (draft.currentStep == 0)
                    _ClientStep(
                      state: state,
                      searchController: _clientSearchController,
                      onSelect: _selectClient,
                      onClear: _clearClient,
                      onContinue: _continueFromClient,
                    )
                  else if (draft.currentStep == 1)
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

class _ClientStep extends StatelessWidget {
  const _ClientStep({
    required this.state,
    required this.searchController,
    required this.onSelect,
    required this.onClear,
    required this.onContinue,
  });

  final CaseCreationState state;
  final TextEditingController searchController;
  final ValueChanged<CaseCreationClient> onSelect;
  final VoidCallback onClear;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final selected = state.draft.selectedClient;

    if (selected != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Selected client',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.vcare.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Continue or change the client for this case.',
            style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
          ),
          const SizedBox(height: 16),
          CaseCreateSelectedClientCard(client: selected, onChange: onClear),
          const SizedBox(height: 24),
          AppButton.elevated(
            onPressed: onContinue,
            text: 'Next',
            icon: LucideIcons.arrowRight,
            iconAlignment: IconAlignment.end,
            color: context.vcare.primary,
            onButtonColor: context.theme.colorScheme.onPrimary,
            height: 48,
            borderRadius: VCareRadius.xlAll,
            fontSize: 15,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Find a client',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.vcare.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Search by name, email, or phone.',
          style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          decoration: caseCreateInputDecoration(
            context,
            hint: 'Search clients…',
            prefixIcon: LucideIcons.search,
            suffix: state.searchingClients
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (state.clientSearchOperation.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              state.clientSearchOperation.errorMessage ??
                  'Unable to search clients.',
              style: TextStyle(fontSize: 13, color: context.vcare.destructive),
            ),
          ),
        if (!state.searchingClients && state.clientResults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No clients found.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
            ),
          )
        else
          for (final client in state.clientResults)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CaseCreateSearchResultTile(
                title: client.fullName,
                subtitle: _clientSubtitle(client),
                onTap: () => onSelect(client),
              ),
            ),
      ],
    );
  }

  String _clientSubtitle(CaseCreationClient client) {
    final parts = <String>[
      if (client.email.trim().isNotEmpty) client.email.trim(),
      if (client.phone.trim().isNotEmpty) client.phone.trim(),
    ];
    return parts.join(' · ');
  }
}
