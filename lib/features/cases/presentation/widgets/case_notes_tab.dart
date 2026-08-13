import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_detail_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_notes_state.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_card.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_composer.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_edit_form.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Notes tab: note list + composer, with optional cloned-source notes.
class CaseNotesTab extends ConsumerStatefulWidget {
  const CaseNotesTab({
    super.key,
    required this.caseId,
    this.clonedFromCaseId,
  });

  final String caseId;
  final String? clonedFromCaseId;

  @override
  ConsumerState<CaseNotesTab> createState() => _CaseNotesTabState();
}

class _CaseNotesTabState extends ConsumerState<CaseNotesTab> {
  final ScrollController _scrollController = ScrollController();

  String? _editingNoteId;
  bool _showSourceNotes = false;

  String? get _sourceCaseId {
    final id = widget.clonedFromCaseId?.trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  @override
  void initState() {
    super.initState();
    // Notes may already be cached, in which case the listener never fires.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final status = resolveLatestCaseNoteStatusOrNull(
        ref.read(caseNotesStateProvider(widget.caseId)).notes,
      );
      if (status != null) _applyHeaderStatus(status);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applyHeaderStatus(CaseStatus status) {
    ref
        .read(caseDetailStateProvider(widget.caseId).notifier)
        .applyNoteStatus(status);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (!position.hasContentDimensions) return;
      _scrollController.jumpTo(position.maxScrollExtent);
    });
  }

  void _toggleSourceNotes() {
    final sourceId = _sourceCaseId;
    if (sourceId == null) return;

    final next = !_showSourceNotes;
    setState(() {
      _showSourceNotes = next;
      if (next) _editingNoteId = null;
    });

    if (next) {
      ref.read(caseNotesStateProvider(sourceId).notifier).fetchNotes();
    }
  }

  Future<void> _toggleAccess(CaseNote note) async {
    await ref
        .read(caseNotesStateProvider(widget.caseId).notifier)
        .toggleNoteAccess(
          note: note,
          onCompleted: (isPublic, error) {
            if (!mounted) return;
            context.showVcareToast(
              title: error ??
                  (isPublic ? 'Note is now public' : 'Note is now private'),
              variant: error == null
                  ? VcareToastVariant.success
                  : VcareToastVariant.destructive,
            );
          },
        );
  }

  Future<void> _saveEdit(
    CaseNote note, {
    required String content,
    required CaseStatus status,
    required String accessType,
  }) async {
    final trimmed = content.trim();

    await ref
        .read(caseNotesStateProvider(widget.caseId).notifier)
        .updateNote(
          noteId: note.id,
          note: trimmed.isEmpty ? null : trimmed,
          status: status,
          accessType: accessType,
          onCompleted: (updated, error) {
            if (!mounted) return;
            if (error != null) {
              context.showVcareToast(
                title: error,
                variant: VcareToastVariant.destructive,
              );
              return;
            }

            setState(() => _editingNoteId = null);
            _syncHeaderStatus(note.id, status);
            context.showVcareToast(
              title: 'Note updated',
              variant: VcareToastVariant.success,
            );
          },
        );
  }

  /// Mirrors the header status when the edited note is the most recent one.
  void _syncHeaderStatus(String noteId, CaseStatus status) {
    final notes = ref.read(caseNotesStateProvider(widget.caseId)).notes;
    final updated = [
      for (final note in notes)
        note.id == noteId ? note.copyWith(status: status) : note,
    ];
    ref
        .read(caseDetailStateProvider(widget.caseId).notifier)
        .applyNoteStatus(resolveLatestCaseNoteStatus(updated, status));
  }

  Future<void> _confirmDelete(CaseNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
          'This will permanently delete the note and its attachments.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.vcare.destructive,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref
        .read(caseNotesStateProvider(widget.caseId).notifier)
        .deleteNote(
          noteId: note.id,
          onCompleted: (success, error) {
            if (!mounted) return;
            if (success && _editingNoteId == note.id) {
              setState(() => _editingNoteId = null);
            }
            context.showVcareToast(
              title: success ? 'Note deleted' : (error ?? 'Delete failed'),
              variant: success
                  ? VcareToastVariant.success
                  : VcareToastVariant.destructive,
            );
          },
        );
  }

  void _showSummary(List<CaseNote> notes) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.sparkles, size: 16, color: context.vcare.primary),
            const SizedBox(width: 8),
            const Text('AI Notes Summary'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            buildCaseNoteSummary(notes),
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caseNotesStateProvider(widget.caseId));
    final sourceId = _sourceCaseId;
    final sourceState = sourceId == null
        ? null
        : ref.watch(caseNotesStateProvider(sourceId));

    ref.listen(
      caseNotesStateProvider(widget.caseId).select((s) => s.notes.length),
      (previous, next) {
        if (next > 0 && !_showSourceNotes) _scrollToBottom();
      },
    );

    // The header status always reflects the most recent note that carries one.
    ref.listen(
      caseNotesStateProvider(
        widget.caseId,
      ).select((s) => resolveLatestCaseNoteStatusOrNull(s.notes)),
      (previous, next) {
        if (next == null || next == previous) return;
        _applyHeaderStatus(next);
      },
    );

    return Column(
      children: [
        _CaseNotesHeaderActions(
          hasCloneSource: sourceId != null,
          isSourceLoading: sourceState?.isInitialLoading ?? false,
          isShowingSourceNotes: _showSourceNotes,
          onToggleSourceNotes: _toggleSourceNotes,
          canSummarize: state.notes.length >= caseNoteSummaryMinimumCount,
          onSummarize: () => _showSummary(state.notes),
        ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            physics: VcareRefreshScrollView.physics,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: _showSourceNotes && sourceId != null
                ? [
                    _SourceNotesPanel(
                      title: 'Notes from source case '
                          '${formatCaseNumber(sourceId)}',
                      state: sourceState!,
                      onRetry: () => ref
                          .read(caseNotesStateProvider(sourceId).notifier)
                          .fetchNotes(),
                    ),
                  ]
                : _buildNotes(state),
          ),
        ),
        CaseNoteComposer(caseId: widget.caseId),
      ],
    );
  }

  List<Widget> _buildNotes(CaseNotesStateData state) {
    if (state.isInitialLoading) {
      return const [_NoteSkeleton(), SizedBox(height: 24), _NoteSkeleton()];
    }

    if (state.error != null && state.notes.isEmpty) {
      return [
        VcareInlineErrorCard(
          message: state.error,
          onRetry: () => ref
              .read(caseNotesStateProvider(widget.caseId).notifier)
              .fetchNotes(),
        ),
      ];
    }

    if (state.notes.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No notes yet. Add the first note below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.vcare.mutedForeground,
            ),
          ),
        ),
      ];
    }

    return [
      for (var i = 0; i < state.notes.length; i++) ...[
        if (i > 0) const SizedBox(height: 24),
        if (state.notes[i].id == _editingNoteId)
          CaseNoteEditForm(
            caseId: widget.caseId,
            note: state.notes[i],
            isSaving: state.mutating,
            onCancel: () => setState(() => _editingNoteId = null),
            onSave: ({
              required content,
              required status,
              required accessType,
            }) => _saveEdit(
              state.notes[i],
              content: content,
              status: status,
              accessType: accessType,
            ),
          )
        else
          CaseNoteCard(
            note: state.notes[i],
            actionsEnabled: !state.mutating,
            isTogglingAccess:
                state.accessTogglingNoteId == state.notes[i].id,
            onEdit: () => setState(() => _editingNoteId = state.notes[i].id),
            onDelete: () => _confirmDelete(state.notes[i]),
            onToggleAccess: () => _toggleAccess(state.notes[i]),
          ),
      ],
    ];
  }
}

class _CaseNotesHeaderActions extends StatelessWidget {
  const _CaseNotesHeaderActions({
    required this.hasCloneSource,
    required this.isSourceLoading,
    required this.isShowingSourceNotes,
    required this.onToggleSourceNotes,
    required this.canSummarize,
    required this.onSummarize,
  });

  final bool hasCloneSource;
  final bool isSourceLoading;
  final bool isShowingSourceNotes;
  final VoidCallback onToggleSourceNotes;
  final bool canSummarize;
  final VoidCallback onSummarize;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 30),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: vcare.mutedForeground,
      side: BorderSide(color: vcare.border),
      shape: RoundedRectangleBorder(borderRadius: VCareRadius.mdAll),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (hasCloneSource) ...[
            OutlinedButton.icon(
              onPressed: isSourceLoading ? null : onToggleSourceNotes,
              icon: isSourceLoading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.copy, size: 12),
              label: Text(
                isShowingSourceNotes ? 'Hide Source Notes' : 'Clone Case Notes',
              ),
              style: buttonStyle,
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton.icon(
            onPressed: canSummarize ? onSummarize : null,
            icon: const Icon(LucideIcons.sparkles, size: 12),
            label: const Text('Summarize Notes'),
            style: buttonStyle,
          ),
        ],
      ),
    );
  }
}

class _SourceNotesPanel extends StatelessWidget {
  const _SourceNotesPanel({
    required this.title,
    required this.state,
    required this.onRetry,
  });

  final String title;
  final CaseNotesStateData state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.4),
        borderRadius: VCareRadius.lgAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: vcare.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            if (state.isInitialLoading)
              const Column(
                children: [
                  _NoteSkeleton(),
                  SizedBox(height: 16),
                  _NoteSkeleton(),
                ],
              )
            else if (state.error != null && state.notes.isEmpty)
              VcareInlineErrorCard(message: state.error, onRetry: onRetry)
            else if (state.notes.isEmpty)
              Text(
                'No notes found on source case.',
                style: TextStyle(
                  fontSize: 13,
                  color: vcare.mutedForeground,
                ),
              )
            else
              for (var i = 0; i < state.notes.length; i++) ...[
                if (i > 0) const SizedBox(height: 24),
                CaseNoteCard(note: state.notes[i], readOnly: true),
              ],
          ],
        ),
      ),
    );
  }
}

class _NoteSkeleton extends StatelessWidget {
  const _NoteSkeleton();

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: vcare.muted, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 12,
                width: 140,
                decoration: BoxDecoration(
                  color: vcare.muted,
                  borderRadius: VCareRadius.smAll,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: vcare.muted,
                  borderRadius: VCareRadius.smAll,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 220,
                decoration: BoxDecoration(
                  color: vcare.muted,
                  borderRadius: VCareRadius.smAll,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
