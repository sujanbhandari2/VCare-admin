import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_task_detail_state_provider.dart';
import 'package:vcare_admin/features/my_tasks/utils/my_task_formatters.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class MyTaskNotesSection extends ConsumerStatefulWidget {
  const MyTaskNotesSection({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<MyTaskNotesSection> createState() => _MyTaskNotesSectionState();
}

class _MyTaskNotesSectionState extends ConsumerState<MyTaskNotesSection> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _editingNoteId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    final notifier = ref.read(
      myTaskDetailStateProvider(widget.taskId).notifier,
    );

    final ok = _editingNoteId == null
        ? await notifier.addNote(text)
        : await notifier.updateNote(noteId: _editingNoteId!, note: text);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) {
        _controller.clear();
        _editingNoteId = null;
      }
    });

    if (!ok) {
      context.showVcareToast(
        title: context.appLocalization.my_tasks_failed_save_note,
        variant: VcareToastVariant.destructive,
      );
    }
  }

  Future<void> _delete(String noteId) async {
    final ok = await ref
        .read(myTaskDetailStateProvider(widget.taskId).notifier)
        .deleteNote(noteId);
    if (!mounted) return;
    if (!ok) {
      context.showVcareToast(
        title: context.appLocalization.my_tasks_failed_delete_note,
        variant: VcareToastVariant.destructive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final state = ref.watch(myTaskDetailStateProvider(widget.taskId));
    final notes = state.notes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.my_tasks_notes,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: vcare.foreground,
          ),
        ),
        const SizedBox(height: 8),
        if (state.notesLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (notes.isEmpty)
          Text(
            l10n.my_tasks_no_notes,
            style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
          )
        else
          ...notes.reversed.map((note) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: vcare.muted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.text,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${note.displayAuthor} · ${formatMyTaskShortDate(note.createdAt)}'
                              '${note.isEdited ? ' ${l10n.my_tasks_note_edited}' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: vcare.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _editingNoteId = note.id;
                            _controller.text = note.text;
                          });
                        },
                        icon: const Icon(LucideIcons.pencil, size: 14),
                        visualDensity: VisualDensity.compact,
                        color: vcare.mutedForeground,
                      ),
                      IconButton(
                        onPressed: () => _delete(note.id),
                        icon: const Icon(LucideIcons.trash2, size: 14),
                        visualDensity: VisualDensity.compact,
                        color: vcare.destructive,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: _editingNoteId == null
                      ? l10n.my_tasks_add_note_hint
                      : l10n.my_tasks_edit_note_hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 3,
                enabled: !_submitting,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _editingNoteId == null
                          ? LucideIcons.send
                          : LucideIcons.check,
                      size: 16,
                    ),
            ),
          ],
        ),
        if (_editingNoteId != null)
          TextButton(
            onPressed: () {
              setState(() {
                _editingNoteId = null;
                _controller.clear();
              });
            },
            child: Text(l10n.my_tasks_cancel_edit),
          ),
      ],
    );
  }
}
