import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

class CaseCreateSummaryStep extends StatelessWidget {
  const CaseCreateSummaryStep({
    super.key,
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
              _CaseCreateSummaryRow(
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
              _CaseCreateSummaryRow(
                label: 'Case type',
                value: draft.selectedType ?? '—',
              ),
              const SizedBox(height: 16),
              _CaseCreateSummaryRow(
                label: 'Assignee',
                value: assignee?.fullName ?? 'Unassigned',
              ),
              const SizedBox(height: 16),
              _CaseCreateSummaryRow(
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

class _CaseCreateSummaryRow extends StatelessWidget {
  const _CaseCreateSummaryRow({required this.label, required this.value});

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
