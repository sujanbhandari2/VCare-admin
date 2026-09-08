import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_create_shared_widgets.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

class CaseCreateDetailsStep extends StatelessWidget {
  const CaseCreateDetailsStep({
    super.key,
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
              CaseCreateTypeChip(
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
