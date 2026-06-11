import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/data/request_file_item.dart';
import 'package:vcare_admin/features/cases/utils/cases_utils.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_activity_status_chip.dart';
import 'package:vcare_admin/features/shell/data/shell_mock_data.dart';

class RequestDetailHeader extends StatelessWidget {
  const RequestDetailHeader({
    super.key,
    required this.request,
    required this.filesOpen,
    required this.onFilesToggle,
    required this.onShowDetails,
    required this.files,
    required this.onAddFile,
    required this.onPreviewFile,
  });

  final CareRequest request;
  final bool filesOpen;
  final VoidCallback onFilesToggle;
  final VoidCallback onShowDetails;
  final List<RequestFileItem> files;
  final VoidCallback onAddFile;
  final void Function(RequestAttachment file) onPreviewFile;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final typeLabel = ShellMockData.requestTypeLabel(request.type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                      request.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      typeLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              _InfoDetailsButton(onPressed: onShowDetails),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              HomeActivityStatusChip(label: casesStatusLabel(request.status)),
              const SizedBox(width: 8),
              _FilesToggleButton(
                count: files.length,
                expanded: filesOpen,
                onTap: onFilesToggle,
              ),
            ],
          ),
          if (filesOpen)
            _FilesPanel(
              files: files,
              onAddFile: onAddFile,
              onPreviewFile: onPreviewFile,
            ),
        ],
      ),
    );
  }
}

/// Parity with vcareapp `RequestDetailsSheet` trigger (Info button).
class _InfoDetailsButton extends StatelessWidget {
  const _InfoDetailsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Semantics(
      button: true,
      label: 'Request details',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              LucideIcons.info,
              size: 16,
              color: vcare.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilesToggleButton extends StatelessWidget {
  const _FilesToggleButton({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      shape: StadiumBorder(side: BorderSide(color: vcare.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.paperclip,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 4),
              const Text(
                'Files',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(fontSize: 10, color: vcare.mutedForeground),
              ),
              Transform.rotate(
                angle: expanded ? 3.14159 : 0,
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 12,
                  color: vcare.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilesPanel extends StatelessWidget {
  const _FilesPanel({
    required this.files,
    required this.onAddFile,
    required this.onPreviewFile,
  });

  final List<RequestFileItem> files;
  final VoidCallback onAddFile;
  final void Function(RequestAttachment file) onPreviewFile;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Text(
              files.isEmpty
                  ? 'ATTACHED FILES'
                  : 'ATTACHED FILES (${files.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: vcare.mutedForeground,
              ),
            ),
          ),
          Divider(height: 1, color: vcare.border),
          if (files.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: vcare.muted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      LucideIcons.paperclip,
                      color: vcare.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No files yet',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attach bills, EOBs, ID cards, or photos so your advocate has what they need.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onAddFile,
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Add a file'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < files.length; i++) ...[
              _FileRow(
                file: files[i],
                onPreview: () => onPreviewFile(files[i].attachment),
              ),
              if (i < files.length - 1) Divider(height: 1, color: vcare.border),
            ],
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onPreview});

  final RequestFileItem file;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final attachment = file.attachment;
    final isImg = attachment.dataUrl.startsWith('data:image/');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPreview,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    if (isImg)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(attachment.dataUrl.split(',').last),
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _FileIcon(isImg: false),
                        ),
                      )
                    else
                      _FileIcon(isImg: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachment.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_shortDate(file.at)} · ${file.sender == 'me' ? 'You' : 'Advocate'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: vcare.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onPreview,
            icon: Icon(
              LucideIcons.download,
              size: 16,
              color: vcare.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.isImg});

  final bool isImg;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: vcare.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isImg ? LucideIcons.image : LucideIcons.fileText,
        size: 16,
        color: vcare.mutedForeground,
      ),
    );
  }
}
