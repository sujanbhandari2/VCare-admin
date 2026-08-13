import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_documents_state_provider.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_upload_constants.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_type_picker_sheet.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class ClientUploadDocumentSheet extends StatelessWidget {
  const ClientUploadDocumentSheet({
    super.key,
    required this.clientId,
    required this.hostContext,
    required this.documentType,
  });

  final String clientId;
  final BuildContext hostContext;
  final String documentType;

  static final _picker = ImagePicker();

  static Future<void> show(BuildContext context, {required String clientId}) async {
    final documentType = await DocumentsTypePickerSheet.show(
      context,
      includeW9: false,
    );
    if (!context.mounted ||
        documentType == null ||
        documentType.trim().isEmpty) {
      return;
    }

    await context.showBottomSheet<void>(
      builder: (sheetContext) => ClientUploadDocumentSheet(
        clientId: clientId,
        hostContext: context,
        documentType: documentType.trim().isEmpty
            ? defaultDocumentTypeLabel
            : documentType.trim(),
      ),
    );
  }

  static Future<void> _uploadFile(
    ProviderContainer container,
    String clientId,
    BuildContext context, {
    required String documentType,
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
          documentType: documentType,
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
    BuildContext context, {
    required String documentType,
  }) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!context.mounted) return;
    await _uploadFile(
      container,
      clientId,
      context,
      documentType: documentType,
      name: image.name,
      bytes: bytes,
      mime: 'image/jpeg',
    );
  }

  static Future<void> takePicture(
    ProviderContainer container,
    String clientId,
    BuildContext context, {
    required String documentType,
  }) async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!context.mounted) return;
    await _uploadFile(
      container,
      clientId,
      context,
      documentType: documentType,
      name: image.name,
      bytes: bytes,
      mime: 'image/jpeg',
    );
  }

  static Future<void> chooseFile(
    ProviderContainer container,
    String clientId,
    BuildContext context, {
    required String documentType,
  }) async {
    // Matches web client accept: images, pdf, doc/docx, txt
    const typeGroups = [
      XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
        mimeTypes: ['image/*'],
      ),
      XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'doc', 'docx', 'txt'],
        mimeTypes: [
          'application/pdf',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'text/plain',
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
      documentType: documentType,
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Type: $documentType',
              style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
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
                    documentType: documentType,
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
                    documentType: documentType,
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
                    documentType: documentType,
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
    required String documentType,
    required Future<void> Function(
      ProviderContainer container,
      String clientId,
      BuildContext context, {
      required String documentType,
    })
    action,
  }) {
    final container = ProviderScope.containerOf(hostContext);
    sheetContext.pop();
    Future<void>.delayed(const Duration(milliseconds: 225), () {
      if (!hostContext.mounted) return;
      action(container, clientId, hostContext, documentType: documentType);
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
        borderRadius: VCareRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.vcare.primary.withValues(alpha: 0.1),
                  borderRadius: VCareRadius.lgAll,
                ),
                child: Icon(icon, size: 16, color: context.vcare.primary),
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
