import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/cases/presentation/widgets/request_new_dashed_border.dart';
import 'package:flutter_template/features/cases/presentation/widgets/request_new_voice_recorder.dart';
import 'package:flutter_template/features/cases/utils/request_attachments.dart';
import 'package:flutter_template/features/cases/utils/request_new_utils.dart';
import 'package:flutter_template/features/home/data/home_models.dart';

class RequestNewStepAttachments extends StatelessWidget {
  const RequestNewStepAttachments({
    super.key,
    required this.attachments,
    required this.description,
    required this.categoryValue,
    required this.onPickImage,
    required this.onPickFile,
    required this.onVoiceRecorded,
    required this.onRemove,
  });

  final List<RequestAttachment> attachments;
  final String description;
  final String categoryValue;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final void Function({
    required String name,
    required String dataUrl,
    required int size,
  })
  onVoiceRecorded;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final categoryLabel = requestTypeLabel(categoryValue) ?? categoryValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add attachments',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Photos of bills, EOBs, or letters help us help you faster. Optional.',
          style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AttachmentPickerTile(
                icon: LucideIcons.camera,
                label: 'Take photo',
                onTap: onPickImage,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AttachmentPickerTile(
                icon: LucideIcons.paperclip,
                label: 'Upload file',
                onTap: onPickFile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RequestNewVoiceRecorder(onRecorded: onVoiceRecorded),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final attachment in attachments)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _AttachmentRow(
                attachment: attachment,
                onRemove: () => onRemove(attachment.id),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: vcare.muted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: vcare.mutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Category',
                style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              ),
              Text(
                categoryLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your request',
                style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              ),
              Text(
                description.trim().isEmpty ? '—' : description.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttachmentPickerTile extends StatelessWidget {
  const _AttachmentPickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: RequestNewDashedBorder(
          color: vcare.border,
          radius: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(icon, size: 20, color: vcare.mutedForeground),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: vcare.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment, required this.onRemove});

  final RequestAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isAudio = isRequestAudioAttachment(
      attachment.dataUrl,
      attachment.name,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: vcare.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (isAudio) ...[
            Icon(LucideIcons.mic, size: 14, color: vcare.mutedForeground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ] else ...[
            Icon(LucideIcons.paperclip, size: 14, color: vcare.mutedForeground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
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
