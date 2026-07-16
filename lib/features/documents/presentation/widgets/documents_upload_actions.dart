import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_list_state_provider.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class DocumentsUploadActions extends ConsumerStatefulWidget {
  const DocumentsUploadActions({super.key});

  @override
  ConsumerState<DocumentsUploadActions> createState() =>
      _DocumentsUploadActionsState();
}

class _DocumentsUploadActionsState extends ConsumerState<DocumentsUploadActions> {
  static final _imagePicker = ImagePicker();
  bool _isUploading = false;

  Future<({int uploaded, int failed})> _uploadFiles(List<XFile> files) async {
    var uploaded = 0;
    var failed = 0;

    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final mime = mimeTypeFromFileName(file.name);
        final baseName = file.name.trim().isEmpty ? 'document' : file.name;
        final displayName = mime.startsWith('image/')
            ? '${baseName.replaceAll(RegExp(r'\.[^.]+$'), '')}.jpg'
            : baseName;

        await ref.read(documentsListStateProvider.notifier).uploadDocument(
          fileName: displayName,
          bytes: bytes,
          refreshList: false,
          onCompleted: (success, _) {
            if (success) {
              uploaded++;
            } else {
              failed++;
            }
          },
        );
      } catch (_) {
        failed++;
      }
    }

    if (uploaded > 0) {
      await ref.read(documentsListStateProvider.notifier).refresh();
    }

    return (uploaded: uploaded, failed: failed);
  }

  Future<void> _handleFiles(List<XFile> files) async {
    if (files.isEmpty || _isUploading) return;

    setState(() => _isUploading = true);

    final result = await _uploadFiles(files);

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (result.uploaded > 0) {
      context.showVcareToast(
        title:
            'Uploaded ${result.uploaded} file${result.uploaded > 1 ? 's' : ''}',
        variant: VcareToastVariant.success,
      );
    } else if (result.failed > 0) {
      context.showVcareToast(
        title: 'Upload failed',
        variant: VcareToastVariant.destructive,
      );
    }
  }

  Future<void> _pickFiles() async {
    const acceptedTypes = <XTypeGroup>[
      XTypeGroup(
        label: 'documents',
        extensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg', 'webp'],
      ),
      XTypeGroup(
        label: 'audio',
        extensions: ['mp3', 'wav', 'm4a', 'webm', 'ogg'],
      ),
    ];

    final files = await openFiles(acceptedTypeGroups: acceptedTypes);
    if (!mounted || files.isEmpty) return;

    await _handleFiles(
      files.map((file) => XFile(file.path, name: file.name)).toList(),
    );
  }

  Future<void> _takePhoto() async {
    if (_isUploading) return;

    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (!mounted || image == null) return;

    await _handleFiles([image]);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_UploadAction>(
      tooltip: 'Upload',
      enabled: !_isUploading,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        switch (action) {
          case _UploadAction.chooseFiles:
            _pickFiles();
          case _UploadAction.takePhoto:
            _takePhoto();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _UploadAction.chooseFiles,
          child: _UploadMenuRow(
            icon: LucideIcons.paperclip,
            label: 'Choose files',
          ),
        ),
        const PopupMenuItem(
          value: _UploadAction.takePhoto,
          child: _UploadMenuRow(
            icon: LucideIcons.camera,
            label: 'Take photo',
          ),
        ),
      ],
      child: Material(
        color: VCareColors.primary,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUploading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VCareColors.primaryForeground,
                  ),
                )
              else
                Icon(
                  LucideIcons.upload,
                  size: 16,
                  color: VCareColors.primaryForeground,
                ),
              const SizedBox(width: 6),
              Text(
                _isUploading ? 'Uploading…' : 'Upload',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VCareColors.primaryForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _UploadAction { chooseFiles, takePhoto }

class _UploadMenuRow extends StatelessWidget {
  const _UploadMenuRow({required this.icon, required this.label});

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
