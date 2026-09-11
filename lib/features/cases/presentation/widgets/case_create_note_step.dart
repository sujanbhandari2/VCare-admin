import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_creation_state.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_shared_widgets.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

class CaseCreateNoteStep extends StatelessWidget {
  const CaseCreateNoteStep({
    super.key,
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
          decoration: caseCreateInputDecoration(
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
          CaseCreateSelectedAssigneeCard(
            assignee: assignee,
            onClear: onClearAssignee,
          ),
        ] else ...[
          TextField(
            controller: assigneeSearchController,
            textInputAction: TextInputAction.search,
            onTap: onSearchAssigneesFocus,
            decoration: caseCreateInputDecoration(
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
              child: CaseCreateSearchResultTile(
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
