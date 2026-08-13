import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_insets.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_scope.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/keyboard_inset.dart';

/// VCare-styled conversation composer for Live Chat thread overrides.
///
/// Attachment options match web Care Team chat:
/// Take photo · Photo library · File · Audio file.
class VcareMessengerThreadComposer extends StatelessWidget {
  const VcareMessengerThreadComposer({
    super.key,
    required this.data,
  });

  final MessengerComposerData data;

  /// Extra space above the nav pill so the input is not covered by the bar.
  static const double _aboveNavGap = 45;

  /// Clears the floating nav pill when the keyboard is closed. Uses
  /// [MediaQuery.viewPadding] because [Scaffold.extendBody] zeroes
  /// [MediaQuery.padding] bottom in the body.
  static double _composerBottomPadding(BuildContext context) {
    if (isSoftKeyboardOpen(context)) {
      return 0;
    }
    if (VCareMobileShellScope.appliesBottomInsetOf(context)) {
      return _aboveNavGap;
    }
    if (isMobileBottomNavVisible(context)) {
      return MediaQuery.viewPaddingOf(context).bottom +
          VCareMobileShellInsets.navOuterBottom +
          VCareMobileShellInsets.pillHeight +
          _aboveNavGap;
    }
    return MediaQuery.viewPaddingOf(context).bottom + _aboveNavGap;
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    // When the shell still insets the tab (inbox list), keep 0 to avoid a
    // double lift. When the conversation thread is open, MainWrapper clears
    // that inset — pad only to the top of the nav pill so the composer sits
    // snug above it (full content padding leaves a large empty band).
    final bottom = _composerBottomPadding(context);

    return AnimatedBuilder(
      animation: data.controller,
      builder: (context, _) {
        final hasText = data.controller.text.trim().isNotEmpty;
        final hasQueuedAttachment = data.pendingAttachments.isNotEmpty;
        final overLimit = pendingAttachmentsOverLimit(data.pendingAttachments);
        final canSend = (hasText || hasQueuedAttachment) &&
            !data.isSending &&
            !data.isRecording &&
            !overLimit;

        return Container(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.replyDraft != null) _ReplyDraftBanner(data: data),
              if (data.isRecording) _RecordingBanner(data: data),
              if (data.pendingAttachments.isNotEmpty)
                _PendingAttachmentsRow(data: data),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: vcare.card,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: vcare.border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: data.isSending || data.isRecording
                          ? null
                          : () => _showAttachmentOptions(context, data),
                      icon: Icon(
                        LucideIcons.paperclip,
                        size: 18,
                        color: vcare.mutedForeground,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: TextField(
                        controller: data.controller,
                        focusNode: data.textFieldFocusNode,
                        enabled: !data.isRecording,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (canSend) {
                            data.onSend();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: hasQueuedAttachment && !hasText
                              ? 'Add a caption… (optional)'
                              : data.hintText,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: vcare.mutedForeground.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        style: data.inputTextStyle ??
                            TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        onChanged: (_) => _handleComposerTyping(data),
                      ),
                    ),
                    IconButton(
                      onPressed: data.isSending
                          ? null
                          : () => _handleMicPressed(data),
                      icon: Icon(
                        data.isRecording ? LucideIcons.square : LucideIcons.mic,
                        size: 18,
                        color: data.isRecording
                            ? context.vcare.destructive
                            : vcare.mutedForeground,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: canSend
                          ? context.vcare.primary
                          : context.vcare.primary.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: canSend ? data.onSend : null,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: data.isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.send,
                                  size: 16,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMicPressed(MessengerComposerData data) {
    if (data.isRecording) {
      (data.onFinishRecording ?? data.onToggleRecording)();
    } else {
      (data.onStartRecording ?? data.onToggleRecording)();
    }
  }

  Future<void> _handleComposerTyping(MessengerComposerData data) async {
    final conversationId = data.typingConversationId?.trim();
    if (conversationId == null || conversationId.isEmpty) {
      return;
    }
    final text = data.controller.text.trim();
    if (text.isNotEmpty) {
      await data.onTypingStart?.call(conversationId);
    } else {
      await data.onTypingStop?.call(conversationId);
    }
  }

  Future<void> _showAttachmentOptions(
    BuildContext context,
    MessengerComposerData data,
  ) async {
    await context.showBottomSheet<void>(
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      topRadius: 18,
      builder: (sheetContext) {
        final vcare = context.vcare;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  data.attachmentSheetTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Order / labels match web CareTeamDetailComposer attach menu.
            if (data.onPickCamera != null)
              _AttachmentOptionTile(
                icon: LucideIcons.camera,
                label: 'Take photo',
                mutedColor: vcare.mutedForeground,
                onTap: () {
                  Navigator.pop(sheetContext);
                  data.onPickCamera!();
                },
              ),
            _AttachmentOptionTile(
              icon: LucideIcons.image,
              label: 'Photo library',
              mutedColor: vcare.mutedForeground,
              onTap: () {
                Navigator.pop(sheetContext);
                data.onPickImage();
              },
            ),
            if (data.onPickDocument != null)
              _AttachmentOptionTile(
                icon: LucideIcons.fileText,
                label: 'File',
                mutedColor: vcare.mutedForeground,
                onTap: () {
                  Navigator.pop(sheetContext);
                  data.onPickDocument!();
                },
              ),
            _AttachmentOptionTile(
              icon: LucideIcons.mic,
              label: 'Audio file',
              mutedColor: vcare.mutedForeground,
              onTap: () {
                Navigator.pop(sheetContext);
                data.onPickAudio();
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _AttachmentOptionTile extends StatelessWidget {
  const _AttachmentOptionTile({
    required this.icon,
    required this.label,
    required this.mutedColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: mutedColor),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}

class _RecordingBanner extends StatelessWidget {
  const _RecordingBanner({required this.data});

  final MessengerComposerData data;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: vcare.muted.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: vcare.border),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: data.isSending
                  ? null
                  : (data.onCancelRecording ?? data.onToggleRecording),
              icon: Icon(
                LucideIcons.trash2,
                size: 18,
                color: context.vcare.destructive,
              ),
              tooltip: 'Discard recording',
              visualDensity: VisualDensity.compact,
            ),
            Icon(LucideIcons.mic, size: 16, color: context.vcare.primary),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Recording…',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: data.isSending
                  ? null
                  : (data.onFinishRecording ?? data.onToggleRecording),
              icon: const Icon(LucideIcons.check, size: 16),
              label: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyDraftBanner extends StatelessWidget {
  const _ReplyDraftBanner({required this.data});

  final MessengerComposerData data;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final draft = data.replyDraft!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${draft.senderLabel}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (draft.preview.trim().isNotEmpty)
                  Text(
                    draft.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: vcare.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: data.onCancelReplyDraft,
            child: const Icon(LucideIcons.x, size: 14),
          ),
        ],
      ),
    );
  }
}

class _PendingAttachmentsRow extends StatelessWidget {
  const _PendingAttachmentsRow({required this.data});

  final MessengerComposerData data;

  bool _isImage(MessengerPickedMedia media) {
    return media.messageType == MessageType.image;
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final pending = data.pendingAttachments;
    final overLimit = pendingAttachmentsOverLimit(pending);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (overLimit)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Attachments exceed the size limit. Remove some to send.',
                style: TextStyle(
                  fontSize: 11,
                  color: context.vcare.destructive,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 128),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < pending.length; i++)
                    _PendingChip(
                      media: pending[i],
                      isImage: _isImage(pending[i]),
                      mutedColor: vcare.muted,
                      borderColor: vcare.border,
                      mutedForeground: vcare.mutedForeground,
                      enabled: !data.isSending,
                      onRemove: data.onRemovePendingAttachment == null
                          ? null
                          : () => data.onRemovePendingAttachment!(i),
                    ),
                ],
              ),
            ),
          ),
          if (data.onClearAllPendingAttachments != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed:
                    data.isSending ? null : data.onClearAllPendingAttachments,
                child: const Text('Clear all'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip({
    required this.media,
    required this.isImage,
    required this.mutedColor,
    required this.borderColor,
    required this.mutedForeground,
    required this.enabled,
    this.onRemove,
  });

  final MessengerPickedMedia media;
  final bool isImage;
  final Color mutedColor;
  final Color borderColor;
  final Color mutedForeground;
  final bool enabled;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final name = media.displayName.trim().isEmpty
        ? 'Attachment'
        : media.displayName.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: mutedColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isImage && media.file.existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(media.file.path),
                width: 20,
                height: 20,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  LucideIcons.paperclip,
                  size: 12,
                  color: mutedForeground,
                ),
              ),
            )
          else
            Icon(
              media.fromRecorder ? LucideIcons.mic : LucideIcons.paperclip,
              size: 12,
              color: mutedForeground,
            ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: enabled ? onRemove : null,
              child: Icon(
                LucideIcons.x,
                size: 12,
                color: mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
