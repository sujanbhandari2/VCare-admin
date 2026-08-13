import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_file.dart';
import 'package:vcare_admin/shared/utils/date_format_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// File row with view / download / delete actions.
class CaseFileRow extends StatelessWidget {
  const CaseFileRow({
    super.key,
    required this.file,
    this.onDelete,
  });

  final CaseFile file;
  final VoidCallback? onDelete;

  Future<void> _openUrl(BuildContext context) async {
    final url = file.url?.trim() ?? '';
    if (!url.isUrl) return;
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final hasUrl = file.url?.trim().isUrl ?? false;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.vcare.primary.withValues(alpha: 0.1),
                borderRadius: VCareRadius.lgAll,
              ),
              child: Icon(
                LucideIcons.fileText,
                size: 16,
                color: context.vcare.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: hasUrl ? () => _openUrl(context) : null,
                    child: Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    [
                      if (file.uploadedBy.trim().isNotEmpty) file.uploadedBy,
                      if (file.uploadedAt.trim().isNotEmpty)
                        formatDisplayDateString(file.uploadedAt),
                      if (file.size.trim().isNotEmpty) file.size,
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 11,
                      color: vcare.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(
                LucideIcons.moreVertical,
                size: 16,
                color: vcare.mutedForeground,
              ),
              onSelected: (value) {
                if (value == 'view' || value == 'download') {
                  _openUrl(context);
                } else if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                if (hasUrl)
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(LucideIcons.eye, size: 16),
                        SizedBox(width: 8),
                        Text('View'),
                      ],
                    ),
                  ),
                if (hasUrl)
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(LucideIcons.download, size: 16),
                        SizedBox(width: 8),
                        Text('Download'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
