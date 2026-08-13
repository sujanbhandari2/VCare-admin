import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_item.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class DocumentsDocRow extends StatelessWidget {
  const DocumentsDocRow({
    super.key,
    required this.item,
    this.isBusy = false,
    this.canManage = false,
    this.onOpen,
    this.onDownload,
    this.onRename,
    this.onDelete,
  });

  final DocumentItem item;
  final bool isBusy;
  final bool canManage;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final sizeLabel = formatDocumentSize(item.size);
    final meta = [
      formatDocumentDate(item.createdAt),
      if (sizeLabel.isNotEmpty) sizeLabel,
    ].join(' · ');
    final documentType = item.documentType?.trim();

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.xlAll,
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                InkWell(
                  onTap: item.canOpen ? onOpen : null,
                  borderRadius: VCareRadius.lgAll,
                  child: _DocumentThumbnail(item: item),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: item.canOpen ? onOpen : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
                        if (documentType != null && documentType.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.vcare.primary.withValues(alpha: 0.05),
                              borderRadius: VCareRadius.fullAll,
                              border: Border.all(
                                color: context.vcare.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              documentType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.vcare.primary,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        _SourceLabel(item: item),
                      ],
                    ),
                  ),
                ),
                if (isBusy)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ),
                  )
                else
                  PopupMenuButton<_DocumentRowAction>(
                    tooltip: 'Actions',
                    padding: EdgeInsets.zero,
                    onSelected: (action) {
                      switch (action) {
                        case _DocumentRowAction.view:
                          onOpen?.call();
                        case _DocumentRowAction.download:
                          onDownload?.call();
                        case _DocumentRowAction.rename:
                          onRename?.call();
                        case _DocumentRowAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (item.canOpen && onOpen != null)
                        const PopupMenuItem(
                          value: _DocumentRowAction.view,
                          child: _MenuRow(
                            icon: LucideIcons.eye,
                            label: 'View',
                          ),
                        ),
                      if (onDownload != null)
                        const PopupMenuItem(
                          value: _DocumentRowAction.download,
                          child: _MenuRow(
                            icon: LucideIcons.download,
                            label: 'Download',
                          ),
                        ),
                      if (canManage && onRename != null)
                        const PopupMenuItem(
                          value: _DocumentRowAction.rename,
                          child: _MenuRow(
                            icon: LucideIcons.pencil,
                            label: 'Rename',
                          ),
                        ),
                      if (canManage && onDelete != null)
                        const PopupMenuItem(
                          value: _DocumentRowAction.delete,
                          child: _MenuRow(
                            icon: LucideIcons.trash2,
                            label: 'Delete',
                          ),
                        ),
                    ],
                    child: Icon(
                      LucideIcons.moreVertical,
                      size: 18,
                      color: vcare.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _DocumentRowAction { view, download, rename, delete }

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.vcare.mutedForeground),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({required this.item});

  final DocumentItem item;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isImage =
        item.kind == DocumentKind.image && item.imagePreviewUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: VCareRadius.lgAll,
      child: Container(
        width: 56,
        height: 56,
        color: vcare.muted,
        alignment: Alignment.center,
        child: isImage
            ? _ImageThumbnail(
                imageUrl: item.imagePreviewUrl,
                cacheKey: 'document:${item.id}',
              )
            : _KindIcon(item: item),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.imageUrl, this.cacheKey});

  final String imageUrl;
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image/svg')) {
      return Icon(
        LucideIcons.image,
        size: 20,
        color: context.vcare.mutedForeground,
      );
    }

    if (isDocumentNetworkUrl(imageUrl)) {
      return VCareCachedImage(
        imageUrl: imageUrl,
        cacheKey: cacheKey,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorWidget: Icon(
          LucideIcons.image,
          size: 20,
          color: context.vcare.mutedForeground,
        ),
      );
    }

    try {
      final payload =
          imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl;
      return Image.memory(
        base64Decode(payload),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(
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
                  color: context.vcare.primary,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              LucideIcons.externalLink,
              size: 12,
              color: context.vcare.primary,
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
