import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_list_state_provider.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_type_picker_sheet.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/features/documents/utils/documents_w9_utils.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class DocumentsUploadActions extends ConsumerStatefulWidget {
  const DocumentsUploadActions({super.key});

  @override
  ConsumerState<DocumentsUploadActions> createState() =>
      _DocumentsUploadActionsState();
}

class _DocumentsUploadActionsState extends ConsumerState<DocumentsUploadActions> {
  static final _imagePicker = ImagePicker();
  bool _isUploading = false;

  bool _resolveCanUploadW9() {
    final statsState = ref.read(agentStatsStateProvider);
    final profile = ref.read(localProfileStateProvider);
    return canUploadW9Document(
      isStatsFetching: statsState.fetching,
      isAgencyAssociated: statsState.data?.isAgencyAssociated,
      hasAgencyGroup: profile.hasAgencyGroup,
    );
  }

  Future<({int uploaded, int failed})> _uploadFiles(
    List<XFile> files, {
    required String documentType,
  }) async {
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
          documentType: documentType,
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

  Future<void> _handleFiles(
    List<XFile> files, {
    required String documentType,
  }) async {
    if (files.isEmpty || _isUploading) return;

    setState(() => _isUploading = true);

    final result = await _uploadFiles(files, documentType: documentType);

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

  Future<void> _pickFiles({required String documentType}) async {
    const acceptedTypes = <XTypeGroup>[
      XTypeGroup(
        label: 'documents',
        extensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'csv',
          'zip',
          'png',
          'jpg',
          'jpeg',
          'webp',
        ],
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
      documentType: documentType,
    );
  }

  Future<void> _takePhoto({required String documentType}) async {
    if (_isUploading) return;

    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (!mounted || image == null) return;

    await _handleFiles([image], documentType: documentType);
  }

  Future<void> _startUploadFlow() async {
    if (_isUploading) return;

    final documentType = await DocumentsTypePickerSheet.show(
      context,
      includeW9: _resolveCanUploadW9(),
    );
    if (!mounted || documentType == null || documentType.trim().isEmpty) {
      return;
    }

    final action = await context.showBottomSheet<_UploadAction>(
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      builder: (sheetContext) => _DocumentsSourceSheet(
        onSelected: (value) => Navigator.of(sheetContext).pop(value),
      ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _UploadAction.chooseFiles:
        await _pickFiles(documentType: documentType);
      case _UploadAction.takePhoto:
        await _takePhoto(documentType: documentType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.vcare.primary,
      borderRadius: VCareRadius.lgAll,
      child: InkWell(
        onTap: _isUploading ? null : _startUploadFlow,
        borderRadius: VCareRadius.lgAll,
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
                    color: context.theme.colorScheme.onPrimary,
                  ),
                )
              else
                Icon(
                  LucideIcons.upload,
                  size: 16,
                  color: context.theme.colorScheme.onPrimary,
                ),
              const SizedBox(width: 6),
              Text(
                _isUploading ? 'Uploading…' : 'Upload',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.theme.colorScheme.onPrimary,
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

class _DocumentsSourceSheet extends StatelessWidget {
  const _DocumentsSourceSheet({required this.onSelected});

  final ValueChanged<_UploadAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UploadMenuRow(
            icon: LucideIcons.paperclip,
            label: 'Choose files',
            onTap: () => onSelected(_UploadAction.chooseFiles),
          ),
          _UploadMenuRow(
            icon: LucideIcons.camera,
            label: 'Take photo',
            onTap: () => onSelected(_UploadAction.takePhoto),
          ),
        ],
      ),
    );
  }
}

class _UploadMenuRow extends StatelessWidget {
  const _UploadMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: context.vcare.mutedForeground),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
