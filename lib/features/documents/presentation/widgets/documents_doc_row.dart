import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_item.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_preview_dialog.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';

class DocumentsDocRow extends StatelessWidget {
  const DocumentsDocRow({
    super.key,
    required this.item,
    this.onDelete,
  });

  final DocumentItem item;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final sizeLabel = formatDocumentSize(item.size);
    final meta = [
      formatDocumentDate(item.createdAt),
      if (sizeLabel.isNotEmpty) sizeLabel,
    ].join(' · ');

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _DocumentThumbnail(item: item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: vcare.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _SourceLabel(item: item),
                    ],
                  ),
                ),
                if (item.kind == DocumentKind.image && item.dataUrl.isNotEmpty)
                  TextButton(
                    onPressed: () => DocumentsPreviewDialog.show(context, item),
                    style: TextButton.styleFrom(
                      foregroundColor: VCareColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: vcare.mutedForeground,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          if (item.kind == DocumentKind.audio && item.dataUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _AudioPreview(dataUrl: item.dataUrl),
            ),
        ],
      ),
    );
  }
}

class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({required this.item});

  final DocumentItem item;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isImage = item.kind == DocumentKind.image && item.dataUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        color: vcare.muted,
        alignment: Alignment.center,
        child: isImage ? _ImageThumbnail(dataUrl: item.dataUrl) : _KindIcon(item: item),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    if (dataUrl.startsWith('data:image/svg')) {
      return Icon(
        LucideIcons.image,
        size: 20,
        color: context.vcare.mutedForeground,
      );
    }

    if (isDocumentNetworkUrl(dataUrl)) {
      return CachedNetworkImage(
        imageUrl: dataUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Icon(
          LucideIcons.image,
          size: 20,
          color: context.vcare.mutedForeground,
        ),
      );
    }

    try {
      final payload = dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
      return Image.memory(
        base64Decode(payload),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          LucideIcons.image,
          size: 20,
          color: context.vcare.mutedForeground,
        ),
      );
    } catch (_) {
      return Icon(
        LucideIcons.image,
        size: 20,
        color: context.vcare.mutedForeground,
      );
    }
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.item});

  final DocumentItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.source) {
      DocumentSource.card => LucideIcons.creditCard,
      _ => switch (item.kind) {
          DocumentKind.audio => LucideIcons.mic,
          DocumentKind.image => LucideIcons.image,
          DocumentKind.file => LucideIcons.fileText,
        },
    };

    return Icon(icon, size: 20, color: context.vcare.mutedForeground);
  }
}

class _SourceLabel extends StatelessWidget {
  const _SourceLabel({required this.item});

  final DocumentItem item;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    if (item.hasSourceLink) {
      return InkWell(
        onTap: () {
          context.pushNamed(
            item.sourceRouteName!,
            pathParameters: item.sourceRouteParameters ?? const {},
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                item.sourceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: VCareColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              LucideIcons.externalLink,
              size: 12,
              color: VCareColors.primary,
            ),
          ],
        ),
      );
    }

    return Text(
      item.sourceLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
    );
  }
}

class _AudioPreview extends StatelessWidget {
  const _AudioPreview({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.vcare.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.mic,
            size: 16,
            color: context.vcare.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Audio attachment',
              style: TextStyle(
                fontSize: 12,
                color: context.vcare.mutedForeground,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }
}
