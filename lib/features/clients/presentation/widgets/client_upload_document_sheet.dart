import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_documents_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class ClientUploadDocumentSheet extends StatelessWidget {
  const ClientUploadDocumentSheet({
    super.key,
    required this.clientId,
    required this.hostContext,
  });

  final String clientId;
  final BuildContext hostContext;

  static final _picker = ImagePicker();

  static Future<void> show(BuildContext context, {required String clientId}) {
    return context.showBottomSheet<void>(
      builder: (sheetContext) => ClientUploadDocumentSheet(
        clientId: clientId,
        hostContext: context,
      ),
    );
  }

  static Future<void> _uploadFile(
    ProviderContainer container,
    String clientId,
    BuildContext context, {
    required String name,
    required List<int> bytes,
    required String mime,
  }) async {
    final baseName = name.trim().isEmpty ? 'document' : name;
    final displayName = mime.startsWith('image/')
        ? '${baseName.replaceAll(RegExp(r'\.[^.]+$'), '')}.jpg'
        : baseName;

    await container
        .read(clientDocumentsStateProvider(clientId).notifier)
        .uploadDocument(
          fileName: displayName,
          bytes: bytes,
          onCompleted: (success, error) {
            if (!context.mounted) return;
            if (success) {
              context.showVcareToast(
                title: 'Uploaded 1 file',
                variant: VcareToastVariant.success,
              );
            } else {
              context.showVcareToast(
                title: 'Upload failed',
                description: error,
                variant: VcareToastVariant.destructive,
              );
            }
          },
        );
  }

  static Future<void> pickFromGallery(
    ProviderContainer container,
    String clientId,
    BuildContext context,
  ) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!context.mounted) return;
    await _uploadFile(
      container,
      clientId,
      context,
      name: image.name,
      bytes: bytes,
      mime: 'image/jpeg',
    );
  }

  static Future<void> takePicture(
    ProviderContainer container,
    String clientId,
    BuildContext context,
  ) async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!context.mounted) return;
    await _uploadFile(
      container,
      clientId,
      context,
      name: image.name,
      bytes: bytes,
      mime: 'image/jpeg',
    );
  }

  static Future<void> chooseFile(
    ProviderContainer container,
    String clientId,
    BuildContext context,
  ) async {
    const typeGroups = [
      XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp', 'svg'],
        mimeTypes: ['image/*'],
      ),
      XTypeGroup(
        label: 'Documents',
        extensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'csv',
          'ppt',
          'pptx',
          'rtf',
        ],
        mimeTypes: [
          'application/pdf',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'text/plain',
          'application/vnd.ms-excel',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'text/csv',
          'application/vnd.ms-powerpoint',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          'application/rtf',
        ],
      ),
    ];

    final file = await openFile(acceptedTypeGroups: typeGroups);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final mime = mimeTypeFromFileName(file.name);
    if (!context.mounted) return;
    await _uploadFile(
      container,
      clientId,
      context,
      name: file.name,
      bytes: bytes,
      mime: mime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: vcare.muted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Upload document',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
            child: Column(
              children: [
                _UploadOption(
                  icon: LucideIcons.image,
                  label: 'Upload from gallery',
                  onTap: () => _onOptionSelected(
                    sheetContext: context,
                    hostContext: hostContext,
                    clientId: clientId,
                    action: pickFromGallery,
                  ),
                ),
                _UploadOption(
                  icon: LucideIcons.camera,
                  label: 'Take a picture',
                  onTap: () => _onOptionSelected(
                    sheetContext: context,
                    hostContext: hostContext,
                    clientId: clientId,
                    action: takePicture,
                  ),
                ),
                _UploadOption(
                  icon: LucideIcons.paperclip,
                  label: 'Choose file',
                  onTap: () => _onOptionSelected(
                    sheetContext: context,
                    hostContext: hostContext,
                    clientId: clientId,
                    action: chooseFile,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _onOptionSelected({
    required BuildContext sheetContext,
    required BuildContext hostContext,
    required String clientId,
    required Future<void> Function(
      ProviderContainer container,
      String clientId,
      BuildContext context,
    )
    action,
  }) {
    final container = ProviderScope.containerOf(hostContext);
    sheetContext.pop();
    Future<void>.delayed(const Duration(milliseconds: 225), () {
      if (!hostContext.mounted) return;
      action(container, clientId, hostContext);
    });
  }
}

class _UploadOption extends StatelessWidget {
  const _UploadOption({
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VCareColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 16, color: VCareColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
