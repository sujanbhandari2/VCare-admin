import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/presentation/providers/document_uploads_state_provider.dart';

class DocumentsUploadActions extends ConsumerWidget {
  const DocumentsUploadActions({super.key});

  static final _imagePicker = ImagePicker();

  Future<void> _handleFiles(
    WidgetRef ref,
    BuildContext context,
    List<XFile> files,
  ) async {
    if (files.isEmpty) return;

    var added = 0;
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final mime = _mimeForName(file.name);
        final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

        ref.read(documentUploadsStateProvider.notifier).addUpload(
              name: file.name,
              dataUrl: dataUrl,
              size: bytes.length,
            );
        added++;
      } catch (_) {
        // Ignore unreadable files.
      }
    }

    if (!context.mounted || added == 0) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Uploaded $added file${added > 1 ? 's' : ''}',
        ),
      ),
    );
  }

  Future<void> _pickFiles(WidgetRef ref, BuildContext context) async {
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
    if (!context.mounted || files.isEmpty) return;

    await _handleFiles(
      ref,
      context,
      files.map((file) => XFile(file.path, name: file.name)).toList(),
    );
  }

  Future<void> _takePhoto(WidgetRef ref, BuildContext context) async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (!context.mounted || image == null) return;

    await _handleFiles(ref, context, [image]);
  }

  String _mimeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_UploadAction>(
      tooltip: 'Upload',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        switch (action) {
          case _UploadAction.chooseFiles:
            _pickFiles(ref, context);
          case _UploadAction.takePhoto:
            _takePhoto(ref, context);
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
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.upload,
                  size: 16,
                  color: VCareColors.primaryForeground,
                ),
                SizedBox(width: 6),
                Text(
                  'Upload',
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
