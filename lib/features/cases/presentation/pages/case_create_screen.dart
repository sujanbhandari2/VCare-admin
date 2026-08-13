import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_creation_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_creation_state.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

const _debounceMs = 300;
const _fieldRadius = 12.0;

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
                    _SummaryStep(
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
                    _NoteStep(
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
                    _DetailsStep(
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

/// Step labels: Client / Note / Case Details.
class CaseCreateStepIndicator extends StatelessWidget {
  const CaseCreateStepIndicator({super.key, required this.currentStep});

  final int currentStep;

  static const _labels = ['Client', 'Note', 'Case Details'];

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(_labels.length, (index) {
            final active = index == currentStep;
            final done = index < currentStep;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(
                  right: index < _labels.length - 1 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: done || active ? context.vcare.primary : vcare.muted,
                  borderRadius: VCareRadius.fullAll,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_labels.length, (index) {
            final active = index == currentStep;
            final done = index < currentStep;
            final color = done || active
                ? context.vcare.primary
                : vcare.mutedForeground;
            return Expanded(
              child: Text(
                _labels[index],
                textAlign: index == 0
                    ? TextAlign.start
                    : index == _labels.length - 1
                        ? TextAlign.end
                        : TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            );
          }),
        ),
      ],
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
          _SelectedClientCard(client: selected, onChange: onClear),
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
          decoration: _inputDecoration(
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
              child: _SearchResultTile(
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

class _NoteStep extends StatelessWidget {
  const _NoteStep({
    required this.state,
    required this.noteController,
    required this.assigneeSearchController,
    required this.onConfirmNote,
    required this.onSelectAssignee,
    required this.onClearAssignee,
    required this.onSearchAssigneesFocus,
  });

  final CaseCreationState state;
  final TextEditingController noteController;
  final TextEditingController assigneeSearchController;
  final VoidCallback onConfirmNote;
  final ValueChanged<CaseAssignee> onSelectAssignee;
  final VoidCallback onClearAssignee;
  final VoidCallback onSearchAssigneesFocus;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final draft = state.draft;
    final assignee = draft.selectedAssignee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add a note',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.vcare.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional context for the care team. You can also assign someone.',
          style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: noteController,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: _inputDecoration(
            context,
            hint: 'Add an optional note…',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Assignee (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.vcare.foreground,
          ),
        ),
        const SizedBox(height: 8),
        if (assignee != null) ...[
          _SelectedAssigneeCard(
            assignee: assignee,
            onClear: onClearAssignee,
          ),
        ] else ...[
          TextField(
            controller: assigneeSearchController,
            textInputAction: TextInputAction.search,
            onTap: onSearchAssigneesFocus,
            decoration: _inputDecoration(
              context,
              hint: 'Search team members…',
              prefixIcon: LucideIcons.userPlus,
              suffix: state.searchingAssignees
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
          const SizedBox(height: 8),
          if (state.assigneeSearchOperation.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.assigneeSearchOperation.errorMessage ??
                    'Unable to search assignees.',
                style: TextStyle(fontSize: 13, color: context.vcare.destructive),
              ),
            ),
          for (final item in state.assigneeResults.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SearchResultTile(
                title: item.fullName,
                subtitle: [
                  if (item.role.trim().isNotEmpty) item.role.trim(),
                  if (item.email.trim().isNotEmpty) item.email.trim(),
                ].join(' · '),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: context.vcare.primary.withValues(alpha: 0.12),
                  child: Text(
                    item.initials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.vcare.primary,
                    ),
                  ),
                ),
                onTap: () => onSelectAssignee(item),
              ),
            ),
        ],
        const SizedBox(height: 24),
        AppButton.elevated(
          onPressed: onConfirmNote,
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
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.draft,
    required this.onSelectType,
    required this.onContinue,
  });

  final CaseCreationDraft draft;
  final ValueChanged<String> onSelectType;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Case details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.vcare.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the case type. This is required.',
          style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in caseTypeOptions)
              _TypeChip(
                label: type,
                selected: draft.selectedType == type,
                onTap: () => onSelectType(type),
              ),
          ],
        ),
        const SizedBox(height: 24),
        AppButton.elevated(
          onPressed: onContinue,
          text: 'Review',
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
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.draft,
    required this.submitting,
    required this.onSubmit,
  });

  final CaseCreationDraft draft;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final client = draft.selectedClient;
    final note = draft.initialNote.trim();
    final assignee = draft.selectedAssignee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review & create',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.vcare.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Confirm the details below, then create the case.',
          style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: vcare.card,
            borderRadius: VCareRadius.xlAll,
            border: Border.all(color: vcare.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(
                label: 'Client',
                value: client?.fullName ?? '—',
              ),
              if (client != null &&
                  (client.email.isNotEmpty || client.phone.isNotEmpty)) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (client.email.trim().isNotEmpty) client.email.trim(),
                    if (client.phone.trim().isNotEmpty) client.phone.trim(),
                  ].join(' · '),
                  style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
                ),
              ],
              const SizedBox(height: 16),
              _SummaryRow(
                label: 'Case type',
                value: draft.selectedType ?? '—',
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                label: 'Assignee',
                value: assignee?.fullName ?? 'Unassigned',
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                label: 'Note',
                value: note.isEmpty ? 'None' : note,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppButton.elevated(
          onPressed: submitting ? null : onSubmit,
          text: 'Confirm & Create',
          loading: submitting,
          color: context.vcare.primary,
          onButtonColor: context.theme.colorScheme.onPrimary,
          height: 48,
          borderRadius: VCareRadius.xlAll,
          fontSize: 15,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: vcare.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.vcare.foreground,
          ),
        ),
      ],
    );
  }
}

class _SelectedClientCard extends StatelessWidget {
  const _SelectedClientCard({
    required this.client,
    required this.onChange,
  });

  final CaseCreationClient client;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final subtitle = [
      if (client.email.trim().isNotEmpty) client.email.trim(),
      if (client.phone.trim().isNotEmpty) client.phone.trim(),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: context.vcare.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: context.vcare.primary.withValues(alpha: 0.12),
            child: Icon(LucideIcons.user, size: 18, color: context.vcare.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _SelectedAssigneeCard extends StatelessWidget {
  const _SelectedAssigneeCard({
    required this.assignee,
    required this.onClear,
  });

  final CaseAssignee assignee;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final subtitle = [
      if (assignee.role.trim().isNotEmpty) assignee.role.trim(),
      if (assignee.email.trim().isNotEmpty) assignee.email.trim(),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: context.vcare.primary.withValues(alpha: 0.12),
            child: Text(
              assignee.initials,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.vcare.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignee.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            tooltip: 'Clear assignee',
            icon: Icon(LucideIcons.x, size: 18, color: vcare.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.title,
    required this.onTap,
    this.subtitle = '',
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: vcare.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: selected
          ? context.vcare.primary.withValues(alpha: 0.12)
          : vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.fullAll,
        side: BorderSide(
          color: selected
              ? context.vcare.primary.withValues(alpha: 0.55)
              : vcare.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.fullAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(LucideIcons.check, size: 14, color: context.vcare.primary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? context.vcare.primary : context.vcare.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hint,
  IconData? prefixIcon,
  Widget? suffix,
}) {
  final vcare = context.vcare;
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: vcare.card,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 18, color: vcare.mutedForeground),
    suffixIcon: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: vcare.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: vcare.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: context.vcare.primary, width: 1.5),
    ),
  );
}
