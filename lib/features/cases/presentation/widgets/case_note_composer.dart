import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_detail_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_mention_field.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_status_button.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_insets.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_scope.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/keyboard_inset.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class _PendingNoteFile {
  const _PendingNoteFile({required this.fileName, required this.bytes});

  final String fileName;
  final List<int> bytes;

  _PendingNoteFile copyWith({String? fileName}) {
    return _PendingNoteFile(fileName: fileName ?? this.fileName, bytes: bytes);
  }
}

/// Bottom composer for adding case notes with mentions, access, and status.
class CaseNoteComposer extends ConsumerStatefulWidget {
  const CaseNoteComposer({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseNoteComposer> createState() => _CaseNoteComposerState();
}

class _CaseNoteComposerState extends ConsumerState<CaseNoteComposer> {
  final TextEditingController _controller = TextEditingController();
  final List<_PendingNoteFile> _pendingFiles = [];
  final List<CaseNotePublicUrl> _pendingUrls = [];

  String _accessType = defaultNoteAccessType;
  CaseStatus? _status;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the send button's enabled state in sync with the draft.
  void _onTextChanged() => setState(() {});

  int get _attachmentCount => _pendingFiles.length + _pendingUrls.length;

  Future<void> _showAttachSheet() async {
    final choice = await context.showBottomSheet<String>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) =>
          _AttachOptionsSheet(onSelected: (value) => sheetContext.pop(value)),
    );
    if (choice == null || !mounted) return;

    if (choice == 'device') {
      await _attachFiles();
      return;
    }
    await _attachUrl();
  }

  Future<void> _attachFiles() async {
    final typeGroup = XTypeGroup(
      label: 'Attachments',
      extensions: caseAllowedFileExtensions.toList(),
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty || !mounted) return;

    var rejected = 0;
    for (final file in files) {
      if (_attachmentCount >= caseFileMaxCount) {
        rejected += 1;
        continue;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > caseFileMaxSizeBytes) {
        rejected += 1;
        continue;
      }
      if (!mounted) return;
      setState(() {
        _pendingFiles.add(_PendingNoteFile(fileName: file.name, bytes: bytes));
      });
    }

    if (rejected > 0 && mounted) {
      context.showVcareToast(
        title: 'Some files were skipped',
        description:
            'Unsupported type, over '
            '${caseFileMaxSizeBytes ~/ (1024 * 1024)}MB, or limit reached',
        variant: VcareToastVariant.destructive,
      );
    }
  }

  Future<void> _attachUrl() async {
    if (_attachmentCount >= caseFileMaxCount) {
      context.showVcareToast(
        title: 'Attachment limit reached',
        description: 'Up to $caseFileMaxCount attachments per note',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    final link = await context.showBottomSheet<CaseNotePublicUrl>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AttachUrlSheet(),
    );
    if (link == null || !mounted) return;
    setState(() => _pendingUrls.add(link));
  }

  Future<void> _renamePendingFile(int index) async {
    if (index < 0 || index >= _pendingFiles.length) return;
    final current = _pendingFiles[index];
    final renamed = await showDialog<String>(
      context: context,
      builder: (_) => _RenamePendingFileDialog(initialName: current.fileName),
    );
    if (renamed == null || !mounted) return;
    final trimmed = renamed.trim();
    if (trimmed.isEmpty || trimmed == current.fileName) return;
    setState(() => _pendingFiles[index] = current.copyWith(fileName: trimmed));
  }

  Future<void> _submit(CaseStatus caseStatus) async {
    final note = _controller.text.trim();
    if (note.isEmpty) return;

    final status = _status ?? caseStatus;

    await ref
        .read(caseNotesStateProvider(widget.caseId).notifier)
        .addNote(
          note: note,
          status: status,
          accessType: _accessType,
          files: _pendingFiles
              .map((f) => (fileName: f.fileName, bytes: f.bytes))
              .toList(),
          publicUrls: List.of(_pendingUrls),
          onCompleted: (created, error) {
            if (!mounted) return;
            if (error != null && created == null) {
              context.showVcareToast(
                title: error,
                variant: VcareToastVariant.destructive,
              );
              return;
            }

            ref
                .read(caseDetailStateProvider(widget.caseId).notifier)
                .applyNoteStatus(status);

            _controller.clear();
            setState(() {
              _pendingFiles.clear();
              _pendingUrls.clear();
              _status = null;
              _accessType = defaultNoteAccessType;
              _isExpanded = false;
            });

            context.showVcareToast(
              title: created == null
                  ? 'Note saved with warnings'
                  : 'Note added',
              description: error,
              variant: error == null
                  ? VcareToastVariant.success
                  : VcareToastVariant.destructive,
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final notesState = ref.watch(caseNotesStateProvider(widget.caseId));
    final caseStatus =
        ref.watch(caseDetailStateProvider(widget.caseId)).data?.status ??
        CaseStatus.requested;

    final mutating = notesState.mutating;
    final isPublic = isPublicNoteAccessType(_accessType);
    final canSubmit = !mutating && _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, _bottomPadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_attachmentCount > 0) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _pendingFiles.length; i++)
                  _PendingAttachmentChip(
                    icon: LucideIcons.paperclip,
                    label: _pendingFiles[i].fileName,
                    onTap: mutating ? null : () => _renamePendingFile(i),
                    onRemove: mutating
                        ? null
                        : () => setState(() => _pendingFiles.removeAt(i)),
                  ),
                for (var i = 0; i < _pendingUrls.length; i++)
                  _PendingAttachmentChip(
                    icon: LucideIcons.link2,
                    label: _pendingUrls[i].name,
                    onRemove: mutating
                        ? null
                        : () => setState(() => _pendingUrls.removeAt(i)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Stack(
            fit: StackFit.passthrough,
            children: [
              CaseNoteMentionField(
                caseId: widget.caseId,
                controller: _controller,
                enabled: !mutating,
                minLines: _isExpanded ? 8 : 3,
                maxLines: _isExpanded ? 14 : 6,
                hintText: 'Add a note… use @ to mention',
                placement: CaseMentionPickerPlacement.above,
                contentPadding: const EdgeInsets.fromLTRB(0, 8, 38, 8),
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: IconButton(
                  onPressed: () =>
                      setState(() => _isExpanded = !_isExpanded),
                  tooltip: _isExpanded ? 'Collapse' : 'Expand',
                  icon: Icon(
                    _isExpanded
                        ? LucideIcons.minimize2
                        : LucideIcons.maximize2,
                    size: 14,
                  ),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(30, 30),
                    maximumSize: const Size(30, 30),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: vcare.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ComposerCircleButton(
                    icon: LucideIcons.paperclip,
                    tooltip: 'Attach files or links',
                    onPressed: mutating ? null : _showAttachSheet,
                  ),
                  _ComposerCircleButton(
                    icon: isPublic ? LucideIcons.eye : LucideIcons.eyeOff,
                    tooltip: isPublic
                        ? 'Public — visible to external parties'
                        : 'Private — internal only',
                    color: isPublic ? vcare.primary : vcare.mutedForeground,
                    onPressed: mutating
                        ? null
                        : () => setState(() {
                            _accessType = toggleNoteAccessType(_accessType);
                          }),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CaseNoteStatusButton(
                    status: _status ?? caseStatus,
                    enabled: !mutating,
                    height: 32,
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  FilledButton.icon(
                    onPressed: canSubmit ? () => _submit(caseStatus) : null,
                    icon: mutating
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.send, size: 14),
                    label: const Text('Add Note'),
                    style: FilledButton.styleFrom(
                      backgroundColor: vcare.primary,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sits the composer a few pixels above the floating nav pill.
  ///
  /// Uses [MediaQuery.viewPadding] because [Scaffold.extendBody] zeroes
  /// [MediaQuery.padding] bottom in the body.
  double _bottomPadding(BuildContext context) {
    const aboveNavGap = 8.0;

    if (isSoftKeyboardOpen(context)) {
      return aboveNavGap;
    }
    // Shell already cleared content for the nav — only keep a tight gap.
    if (VCareMobileShellScope.appliesBottomInsetOf(context)) {
      return aboveNavGap;
    }
    if (isMobileBottomNavVisible(context)) {
      return MediaQuery.viewPaddingOf(context).bottom +
          VCareMobileShellInsets.navOuterBottom +
          VCareMobileShellInsets.pillHeight +
          aboveNavGap;
    }
    return MediaQuery.viewPaddingOf(context).bottom + aboveNavGap;
  }
}

/// Round, muted icon button shared by the composer's inline and row actions.
class _ComposerCircleButton extends StatelessWidget {
  const _ComposerCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  static const double _size = 30;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final enabled = onPressed != null;
    final foreground = color ?? vcare.mutedForeground;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: vcare.muted,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              icon,
              size: 14,
              color: enabled ? foreground : foreground.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingAttachmentChip extends StatelessWidget {
  const _PendingAttachmentChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.onRemove,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.muted,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: vcare.mutedForeground),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 2),
              InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    LucideIcons.x,
                    size: 12,
                    color: vcare.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachOptionsSheet extends StatelessWidget {
  const _AttachOptionsSheet({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Attach to note',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
            child: Column(
              children: [
                _AttachOption(
                  icon: LucideIcons.paperclip,
                  label: 'From device',
                  onTap: () => onSelected('device'),
                ),
                _AttachOption(
                  icon: LucideIcons.link,
                  label: 'From URL',
                  onTap: () => onSelected('url'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.vcare.primary.withValues(alpha: 0.1),
                  borderRadius: VCareRadius.lgAll,
                ),
                child: Icon(icon, size: 16, color: context.vcare.primary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachUrlSheet extends StatefulWidget {
  const _AttachUrlSheet();

  @override
  State<_AttachUrlSheet> createState() => _AttachUrlSheetState();
}

class _AttachUrlSheetState extends State<_AttachUrlSheet> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _urlController.text.trim();
    if (!url.isUrl) {
      context.showVcareToast(
        title: 'Enter a valid URL',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    final name = _nameController.text.trim();
    context.pop(
      CaseNotePublicUrl(url: url, name: name.isEmpty ? 'Attachment' : name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Attach from URL',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'Optional',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            AppButton.elevated(text: 'Add link', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _RenamePendingFileDialog extends StatefulWidget {
  const _RenamePendingFileDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenamePendingFileDialog> createState() =>
      _RenamePendingFileDialogState();
}

class _RenamePendingFileDialogState extends State<_RenamePendingFileDialog> {
  late final TextEditingController _controller;
  late final String _extension;

  @override
  void initState() {
    super.initState();
    final parts = splitDocumentFileName(widget.initialName);
    _extension = parts.extension;
    _controller = TextEditingController(text: parts.baseName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizedBaseName(String raw) {
    var baseName = raw.trim();
    if (baseName.isEmpty) return '';

    if (_extension.isNotEmpty) {
      final lower = baseName.toLowerCase();
      final lockedExt = _extension.toLowerCase();
      if (lower.endsWith(lockedExt)) {
        baseName = baseName.substring(0, baseName.length - _extension.length);
      } else {
        final lastDot = baseName.lastIndexOf('.');
        if (lastDot > 0) {
          baseName = baseName.substring(0, lastDot);
        }
      }
    }

    return baseName.trim();
  }

  void _submit() {
    final baseName = _normalizedBaseName(_controller.text);
    if (baseName.isEmpty) return;

    Navigator.pop(
      context,
      joinDocumentFileName(baseName: baseName, extension: _extension),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return AlertDialog(
      title: const Text('Rename attachment'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\\/]'))],
        decoration: InputDecoration(
          hintText: 'File name',
          suffixText: _extension.isNotEmpty ? _extension : null,
          suffixStyle: TextStyle(
            fontSize: 16,
            color: vcare.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
          helperText: _extension.isNotEmpty
              ? 'File extension cannot be changed'
              : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
