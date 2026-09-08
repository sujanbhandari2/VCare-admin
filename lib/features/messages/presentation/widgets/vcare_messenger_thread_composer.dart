import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_state.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_scope.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// VCare-styled conversation composer for Live Chat thread overrides.
///
/// Attachment options match web Care Team chat:
/// Take photo · Photo library · File · Audio file.
class VcareMessengerThreadComposer extends StatefulWidget {
  const VcareMessengerThreadComposer({
    super.key,
    required this.data,
    this.editDraft,
    this.onCancelEditDraft,
  });

  final MessengerComposerData data;
  final MessengerComposerEditDraft? editDraft;
  final VoidCallback? onCancelEditDraft;

  /// Extra space above the nav pill so the input is not covered by the bar.
  static const double _aboveNavGap = 45;

  /// Mirrors [vcare_bottom_navigation] floating pill metrics.
  static const double _navOuterBottom = 8;
  static const double _pillHeight = 78;

  /// Matches package [MessengerComposerBar] typing throttle.
  static const Duration _typingStartMinInterval = Duration(seconds: 2);
  static const Duration _typingStopIdle = Duration(seconds: 2);

  /// True when the IME is visible.
  ///
  /// Must read insets from the platform [View], not [MediaQuery.viewInsets]:
  /// an ancestor [Scaffold] with `resizeToAvoidBottomInset` consumes viewInsets
  /// for its body, so MediaQuery here reports 0 while the keyboard is open —
  /// which previously kept applying nav clearance and floated the field up.
  static bool _isKeyboardOpen(BuildContext context) {
    return MediaQueryData.fromView(View.of(context)).viewInsets.bottom > 0;
  }

  /// Clears the floating nav pill when the keyboard is closed. Uses
  /// [MediaQuery.viewPadding] because [Scaffold.extendBody] zeroes
  /// [MediaQuery.padding] bottom in the body.
  static double _composerBottomPadding(BuildContext context) {
    if (_isKeyboardOpen(context)) {
      return 0;
    }
    if (VCareMobileShellScope.appliesBottomInsetOf(context)) {
      return _aboveNavGap;
    }
    // Mobile tab shell still showing the floating nav (thread open; shell
    // inset cleared by [liveChatMobileThreadVisibleProvider]).
    if (MediaQuery.sizeOf(context).width < 768) {
      return MediaQuery.viewPaddingOf(context).bottom +
          _navOuterBottom +
          _pillHeight +
          _aboveNavGap;
    }
    return MediaQuery.viewPaddingOf(context).bottom + _aboveNavGap;
  }

  @override
  State<VcareMessengerThreadComposer> createState() =>
      _VcareMessengerThreadComposerState();
}

class _VcareMessengerThreadComposerState
    extends State<VcareMessengerThreadComposer> {
  Timer? _idleStopTimer;
  DateTime? _lastTypingStartSent;
  bool _hadNonEmptyForTyping = false;

  MessengerComposerData get data => widget.data;

  bool get _typingEnabled {
    final conversationId = data.typingConversationId?.trim();
    return conversationId != null &&
        conversationId.isNotEmpty &&
        data.onTypingStart != null &&
        data.onTypingStop != null;
  }

  @override
  void initState() {
    super.initState();
    data.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant VcareMessengerThreadComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.controller != data.controller) {
      oldWidget.data.controller.removeListener(_handleTextChanged);
      data.controller.addListener(_handleTextChanged);
    }
    final oldId = oldWidget.data.typingConversationId?.trim();
    final newId = data.typingConversationId?.trim();
    if (oldId != newId) {
      _cancelIdleTimer();
      if (oldId != null &&
          oldId.isNotEmpty &&
          oldWidget.data.onTypingStop != null &&
          _hadNonEmptyForTyping) {
        unawaited(oldWidget.data.onTypingStop!(oldId));
      }
      _lastTypingStartSent = null;
      _hadNonEmptyForTyping = false;
    }
  }

  @override
  void dispose() {
    _cancelIdleTimer();
    data.controller.removeListener(_handleTextChanged);
    if (_hadNonEmptyForTyping && _typingEnabled) {
      final id = data.typingConversationId!.trim();
      unawaited(data.onTypingStop!(id));
    }
    super.dispose();
  }

  void _cancelIdleTimer() {
    _idleStopTimer?.cancel();
    _idleStopTimer = null;
  }

  Future<void> _emitStart() async {
    if (!_typingEnabled) {
      return;
    }
    final id = data.typingConversationId!.trim();
    try {
      await data.onTypingStart!(id);
    } catch (_) {}
  }

  Future<void> _emitStop() async {
    if (!_typingEnabled) {
      return;
    }
    final id = data.typingConversationId!.trim();
    try {
      await data.onTypingStop!(id);
    } catch (_) {}
  }

  void _scheduleIdleStop() {
    if (!_typingEnabled) {
      return;
    }
    _cancelIdleTimer();
    _idleStopTimer = Timer(VcareMessengerThreadComposer._typingStopIdle, () {
      if (!mounted) {
        return;
      }
      _idleStopTimer = null;
      if (data.controller.text.trim().isEmpty) {
        return;
      }
      unawaited(_emitStop());
      _lastTypingStartSent = null;
      _hadNonEmptyForTyping = false;
    });
  }

  void _handleTextChanged() {
    if (!_typingEnabled) {
      return;
    }

    final trimmed = data.controller.text.trim();
    if (trimmed.isEmpty) {
      _cancelIdleTimer();
      if (_hadNonEmptyForTyping) {
        unawaited(_emitStop());
      }
      _lastTypingStartSent = null;
      _hadNonEmptyForTyping = false;
      return;
    }

    _hadNonEmptyForTyping = true;
    final now = DateTime.now();
    final last = _lastTypingStartSent;
    final min = VcareMessengerThreadComposer._typingStartMinInterval;
    if (last == null || now.difference(last) >= min) {
      _lastTypingStartSent = now;
      unawaited(_emitStart());
    }
    _scheduleIdleStop();
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    // When the shell still insets the tab (inbox list), keep modest clearance.
    // When the conversation thread is open, MainWrapper clears that inset —
    // pad only to the top of the nav pill so the composer sits snug above it.
    final bottom = VcareMessengerThreadComposer._composerBottomPadding(context);

    return AnimatedBuilder(
      animation: data.controller,
      builder: (context, _) {
        final hasText = data.controller.text.trim().isNotEmpty;
        final hasQueuedAttachment = data.pendingAttachments.isNotEmpty;
        final overLimit = pendingAttachmentsOverLimit(data.pendingAttachments);
        final canSend = (hasText || hasQueuedAttachment) &&
            !data.isSending &&
            !data.isRecording &&
            !overLimit &&
            (widget.editDraft == null || hasText);
        final hintText = widget.editDraft != null
            ? 'Edit message…'
            : (hasQueuedAttachment && !hasText
                ? 'Add a caption… (optional)'
                : data.hintText);

        return Container(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.editDraft != null)
                _EditDraftBanner(
                  onCancel: widget.onCancelEditDraft,
                ),
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
                      onPressed: data.isSending ||
                              data.isRecording ||
                              widget.editDraft != null
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
                          hintText: hintText,
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
                            ? VCareColors.destructive
                            : vcare.mutedForeground,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: canSend
                          ? VCareColors.primary
                          : VCareColors.primary.withValues(alpha: 0.35),
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

  Future<void> _showAttachmentOptions(
    BuildContext context,
    MessengerComposerData data,
  ) async {
    await context.showBottomSheet<void>(
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
                color: VCareColors.destructive,
              ),
              tooltip: 'Discard recording',
              visualDensity: VisualDensity.compact,
            ),
            Icon(LucideIcons.mic, size: 16, color: VCareColors.primary),
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

class _EditDraftBanner extends StatelessWidget {
  const _EditDraftBanner({this.onCancel});

  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(LucideIcons.pencil, size: 14, color: VCareColors.primary),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Editing message',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(LucideIcons.x, size: 14, color: vcare.mutedForeground),
          ),
        ],
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
                  color: VCareColors.destructive,
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
