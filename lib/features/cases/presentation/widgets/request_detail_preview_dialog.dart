import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/utils/request_attachments.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';

/// Parity with vcareapp `RequestDetailPreviewDialog`.
class RequestDetailPreviewDialog extends StatelessWidget {
  const RequestDetailPreviewDialog({super.key, required this.attachment});

  final RequestAttachment attachment;

  static Future<void> show(BuildContext context, RequestAttachment attachment) {
    return showDialog<void>(
      context: context,
      builder: (context) => RequestDetailPreviewDialog(attachment: attachment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isImg = isRequestImageAttachment(attachment.dataUrl, attachment.name);
    final isPdf =
        attachment.dataUrl.startsWith('data:application/pdf') ||
        attachment.name.toLowerCase().endsWith('.pdf');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: vcare.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: vcare.border),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: isImg
                  ? _ImagePreview(dataUrl: attachment.dataUrl)
                  : isPdf
                  ? _PdfPreview(dataUrl: attachment.dataUrl)
                  : _UnsupportedPreview(name: attachment.name),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(dataUrl.split(',').last);
    return Container(
      color: context.vcare.muted.withValues(alpha: 0.4),
      alignment: Alignment.center,
      child: InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain)),
    );
  }
}

class _PdfPreview extends StatelessWidget {
  const _PdfPreview({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        'PDF preview is not available in the app yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.vcare.mutedForeground, fontSize: 14),
      ),
    );
  }
}

class _UnsupportedPreview extends StatelessWidget {
  const _UnsupportedPreview({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.fileText,
            size: 40,
            color: vcare.mutedForeground.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Preview not available for this file type.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.download, size: 14),
            label: const Text('Close'),
            style: FilledButton.styleFrom(
              backgroundColor: VCareColors.primary,
              foregroundColor: VCareColors.primaryForeground,
            ),
          ),
        ],
      ),
    );
  }
}
