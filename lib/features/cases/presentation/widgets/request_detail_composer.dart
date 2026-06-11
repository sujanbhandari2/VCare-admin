import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/data/pending_attachment.dart';
import 'package:vcare_admin/features/cases/utils/request_attachments.dart';

class RequestDetailComposer extends StatelessWidget {
  const RequestDetailComposer({
    super.key,
    required this.controller,
    required this.pending,
    required this.editingId,
    required this.onSend,
    required this.onAttach,
    required this.onVoice,
    required this.onCancelEdit,
    required this.onRemovePending,
    required this.onRetryPending,
  });

  final TextEditingController controller;
  final List<PendingAttachment> pending;
  final String? editingId;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onVoice;
  final VoidCallback onCancelEdit;
  final void Function(String id) onRemovePending;
  final void Function(String id) onRetryPending;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    // Match [CareTeamDetailScreen] `_ChatComposer` (messages thread).
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canSend =
        controller.text.trim().isNotEmpty ||
        pending.any((item) => item.status == PendingAttachmentStatus.done);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (editingId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: vcare.muted.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Editing message',
                      style: TextStyle(
                        fontSize: 11,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancelEdit,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: VCareColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (pending.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: pending.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  return _PendingRow(
                    item: pending[index],
                    onRemove: () => onRemovePending(pending[index].id),
                    onRetry: () => onRetryPending(pending[index].id),
                  );
                },
              ),
            ),
          if (pending.isNotEmpty) const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: vcare.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: vcare.border),
            ),
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RoundIconButton(
                  icon: LucideIcons.paperclip,
                  onPressed: onAttach,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Write a note',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      hintStyle: TextStyle(
                        color: vcare.mutedForeground.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (canSend) onSend();
                    },
                  ),
                ),
                _RoundIconButton(icon: LucideIcons.mic, onPressed: onVoice),
                _RoundIconButton(
                  icon: LucideIcons.send,
                  onPressed: canSend ? onSend : null,
                  filled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: filled ? VCareColors.primary : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 16,
            color: filled
                ? VCareColors.primaryForeground
                : vcare.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.item,
    required this.onRemove,
    required this.onRetry,
  });

  final PendingAttachment item;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final audio = isRequestAudioAttachment(item.dataUrl, item.name);
    final isError = item.status == PendingAttachmentStatus.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? VCareColors.destructive.withValues(alpha: 0.4)
              : vcare.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            audio ? LucideIcons.mic : LucideIcons.paperclip,
            size: 14,
            color: isError ? VCareColors.destructive : vcare.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.status == PendingAttachmentStatus.uploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.progress / 100,
                        minHeight: 4,
                        backgroundColor: vcare.muted,
                      ),
                    ),
                  ),
                if (isError)
                  Text(
                    item.error ?? 'Failed',
                    style: TextStyle(
                      fontSize: 11,
                      color: VCareColors.destructive,
                    ),
                  ),
              ],
            ),
          ),
          if (isError)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(fontSize: 11)),
            ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(LucideIcons.x, size: 14, color: vcare.mutedForeground),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
