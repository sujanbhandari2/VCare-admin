import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_card.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_mention_field.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_status_button.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Inline editor that replaces a note row while it is being edited.
class CaseNoteEditForm extends ConsumerStatefulWidget {
  const CaseNoteEditForm({
    super.key,
    required this.caseId,
    required this.note,
    required this.onCancel,
    required this.onSave,
    this.isSaving = false,
  });

  final String caseId;
  final CaseNote note;
  final VoidCallback onCancel;
  final void Function({
    required String content,
    required CaseStatus status,
    required String accessType,
  })
  onSave;
  final bool isSaving;

  @override
  ConsumerState<CaseNoteEditForm> createState() => _CaseNoteEditFormState();
}

class _CaseNoteEditFormState extends ConsumerState<CaseNoteEditForm> {
  late final TextEditingController _controller;
  late CaseStatus _status;
  late String _accessType;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.content);
    _status = widget.note.status ?? CaseStatus.requested;
    _accessType = widget.note.accessType ?? defaultNoteAccessType;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSave(
      content: _controller.text,
      status: _status,
      accessType: _accessType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CaseNoteAvatar(initials: widget.note.authorInitials),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: vcare.card,
                  borderRadius: VCareRadius.lgAll,
                  border: Border.all(color: vcare.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: CaseNoteMentionField(
                    caseId: widget.caseId,
                    controller: _controller,
                    autofocus: true,
                    minLines: 2,
                    maxLines: 8,
                    enabled: !widget.isSaving,
                    hintText: 'Update this note… use @ to mention',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CaseNoteAccessEyeButton(
                    isPublic: isPublicNoteAccessType(_accessType),
                    onToggle: widget.isSaving
                        ? null
                        : () => setState(() {
                            _accessType = toggleNoteAccessType(_accessType);
                          }),
                  ),
                  CaseNoteStatusButton(
                    status: _status,
                    enabled: !widget.isSaving,
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  FilledButton.icon(
                    onPressed: widget.isSaving ? null : _submit,
                    icon: widget.isSaving
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.save, size: 12),
                    label: const Text('Save'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.vcare.primary,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.isSaving ? null : widget.onCancel,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: vcare.mutedForeground,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
