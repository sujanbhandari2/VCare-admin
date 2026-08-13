import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/shared/widgets/vcare_option_picker_sheet.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Statuses selectable on a note, matching the web status dropdown.
const List<CaseStatus> caseNoteStatusOptions = CaseStatus.values;

/// Compact status selector standing in for the web `Select` control.
class CaseNoteStatusButton extends StatelessWidget {
  const CaseNoteStatusButton({
    super.key,
    required this.status,
    required this.onChanged,
    this.enabled = true,
    this.height = 30,
  });

  final CaseStatus status;
  final ValueChanged<CaseStatus> onChanged;
  final bool enabled;
  final double height;

  Future<void> _pick(BuildContext context) async {
    final selected = await VcareOptionPickerSheet.show<CaseStatus>(
      context,
      title: 'Note status',
      options: caseNoteStatusOptions,
      labelOf: (value) => value.label,
      selected: status,
    );
    if (selected == null) return;
    onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: enabled ? () => _pick(context) : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size(0, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: vcare.foreground,
          side: BorderSide(color: vcare.border),
          shape: RoundedRectangleBorder(
            borderRadius: VCareRadius.mdAll,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 12,
              color: vcare.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
