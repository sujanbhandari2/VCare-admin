import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';

class ClientDocumentPreviewDialog extends StatelessWidget {
  const ClientDocumentPreviewDialog({super.key, required this.file});

  final ClientFile file;

  static Future<void> show(BuildContext context, ClientFile file) {
    return showDialog<void>(
      context: context,
      builder: (context) => ClientDocumentPreviewDialog(file: file),
    );
  }

  bool get _isImage =>
      file.mime.startsWith('image/') ||
      file.name.toLowerCase().endsWith('.jpg') ||
      file.name.toLowerCase().endsWith('.jpeg') ||
      file.name.toLowerCase().endsWith('.png') ||
      file.name.toLowerCase().endsWith('.gif') ||
      file.name.toLowerCase().endsWith('.webp');

  bool get _isPdf =>
      file.mime == 'application/pdf' ||
      file.name.toLowerCase().endsWith('.pdf');

  bool get _isDataUrl => file.url.startsWith('data:');

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

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
                    file.name,
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
              child: _isImage
                  ? _ImagePreview(file: file, isDataUrl: _isDataUrl)
                  : _isPdf
                  ? _PdfPreview()
                  : _UnsupportedPreview(name: file.name),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.file, required this.isDataUrl});

  final ClientFile file;
  final bool isDataUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.vcare.muted.withValues(alpha: 0.4),
      alignment: Alignment.center,
      child: InteractiveViewer(
        child: isDataUrl
            ? Image.memory(
                base64Decode(file.url.split(',').last),
                fit: BoxFit.contain,
              )
            : CachedNetworkImage(
                imageUrl: file.url,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(LucideIcons.imageOff),
              ),
      ),
    );
  }
}

class _PdfPreview extends StatelessWidget {
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
