import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_mention_content.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_status_chip.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Circular initials avatar used by note rows and the note composer.
class CaseNoteAvatar extends StatelessWidget {
  const CaseNoteAvatar({
    super.key,
    required this.initials,
    this.isComposer = false,
  });

  final String initials;
  final bool isComposer;

  @override
  Widget build(BuildContext context) {
    final tone = isComposer ? context.vcare.secondary : context.vcare.primary;

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials.trim().isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: tone,
        ),
      ),
    );
  }
}

/// A single note: author, timestamp, status, body, attachments, and actions.
class CaseNoteCard extends StatelessWidget {
  const CaseNoteCard({
    super.key,
    required this.note,
    this.readOnly = false,
    this.isTogglingAccess = false,
    this.actionsEnabled = true,
    this.onEdit,
    this.onDelete,
    this.onToggleAccess,
  });

  final CaseNote note;

  /// Hides all mutating actions, e.g. notes shown from a cloned source case.
  final bool readOnly;
  final bool isTogglingAccess;
  final bool actionsEnabled;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleAccess;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final showActions = !readOnly && (note.canEdit || note.canDelete);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CaseNoteAvatar(initials: note.authorInitials),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (note.authorName.trim().isEmpty
                                  ? 'Unknown'
                                  : note.authorName)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: vcare.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatNoteTimestamp(note.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (note.status != null) ...[
                    const SizedBox(width: 6),
                    CaseStatusChip(status: note.status!),
                  ],
                  if (showActions) ...[
                    const SizedBox(width: 2),
                    if (isTogglingAccess)
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      _CaseNoteActionsMenu(
                        note: note,
                        enabled: actionsEnabled,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onToggleAccess: onToggleAccess,
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              CaseNoteMentionContent(content: note.content, tags: note.tags),
              if (note.files.isNotEmpty) ...[
                const SizedBox(height: 8),
                CaseNoteFileLinks(files: note.files),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

enum _CaseNoteMenuAction { toggleAccess, edit, delete }

class _CaseNoteActionsMenu extends StatelessWidget {
  const _CaseNoteActionsMenu({
    required this.note,
    required this.enabled,
    this.onEdit,
    this.onDelete,
    this.onToggleAccess,
  });

  final CaseNote note;
  final bool enabled;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleAccess;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isPublic = isPublicNoteAccessType(note.accessType);
    final canToggleAccess = note.canEdit && enabled && onToggleAccess != null;
    final canEdit = note.canEdit && enabled && onEdit != null;
    final canDelete = note.canDelete && enabled && onDelete != null;

    return PopupMenuButton<_CaseNoteMenuAction>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 4),
      shape: RoundedRectangleBorder(borderRadius: VCareRadius.lgAll),
      enabled: canToggleAccess || canEdit || canDelete,
      onSelected: (value) {
        switch (value) {
          case _CaseNoteMenuAction.toggleAccess:
            onToggleAccess?.call();
          case _CaseNoteMenuAction.edit:
            onEdit?.call();
          case _CaseNoteMenuAction.delete:
            onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        if (note.canEdit)
          PopupMenuItem(
            value: _CaseNoteMenuAction.toggleAccess,
            enabled: canToggleAccess,
            child: Row(
              children: [
                Icon(
                  isPublic ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 14,
                  color: vcare.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(isPublic ? 'Make private' : 'Make public'),
              ],
            ),
          ),
        if (note.canEdit)
          PopupMenuItem(
            value: _CaseNoteMenuAction.edit,
            enabled: canEdit,
            child: const Row(
              children: [
                Icon(LucideIcons.pencil, size: 14),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
        if (note.canDelete)
          PopupMenuItem(
            value: _CaseNoteMenuAction.delete,
            enabled: canDelete,
            child: Row(
              children: [
                Icon(LucideIcons.trash2, size: 14, color: vcare.destructive),
                const SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: vcare.destructive)),
              ],
            ),
          ),
      ],
      icon: Icon(
        LucideIcons.moreVertical,
        size: 16,
        color: vcare.mutedForeground,
      ),
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        maximumSize: const Size(28, 28),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Toggles a note between internal-only and externally visible.
class CaseNoteAccessEyeButton extends StatelessWidget {
  const CaseNoteAccessEyeButton({
    super.key,
    required this.isPublic,
    this.onToggle,
    this.isBusy = false,
    this.size = 28,
  });

  final bool isPublic;
  final VoidCallback? onToggle;
  final bool isBusy;
  final double size;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    if (isBusy) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Tooltip(
      message: isPublic
          ? 'Public — visible to external parties'
          : 'Private — internal only',
      child: _CaseNoteActionButton(
        icon: isPublic ? LucideIcons.eye : LucideIcons.eyeOff,
        color: isPublic ? context.vcare.primary : vcare.mutedForeground,
        onPressed: onToggle,
        size: size,
      ),
    );
  }
}

class _CaseNoteActionButton extends StatelessWidget {
  const _CaseNoteActionButton({
    required this.icon,
    this.color,
    this.onPressed,
    this.size = 28,
  });

  final IconData icon;
  final Color? color;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: Size(size, size),
        maximumSize: Size(size, size),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: color ?? vcare.mutedForeground,
      ),
    );
  }
}

/// Attachment links rendered inline under a note body.
class CaseNoteFileLinks extends StatelessWidget {
  const CaseNoteFileLinks({super.key, required this.files});

  final List<CaseNoteFile> files;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final file in files)
          _CaseNoteFileLink(name: file.name, url: file.url.trim()),
      ],
    );
  }
}

class _CaseNoteFileLink extends StatelessWidget {
  const _CaseNoteFileLink({required this.name, required this.url});

  final String name;
  final String url;

  @override
  Widget build(BuildContext context) {
    final canOpen = url.isUrl;

    return Opacity(
      opacity: canOpen ? 1 : 0.6,
      child: InkWell(
        onTap: canOpen
            ? () => launchUrlString(url, mode: LaunchMode.externalApplication)
            : null,
        borderRadius: VCareRadius.smAll,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.paperclip, size: 12, color: context.vcare.primary),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: context.vcare.primary,
                  decoration: canOpen ? TextDecoration.underline : null,
                  decorationColor: context.vcare.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
