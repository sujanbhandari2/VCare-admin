import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_upload_constants.dart';
import 'package:vcare_admin/features/documents/presentation/providers/document_types_state_provider.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_list_state_provider.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_list_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Bottom-sheet equivalent of web `HomeActivityRow` W-9 Sheet.
class TodoW9FormSheet extends ConsumerStatefulWidget {
  const TodoW9FormSheet({super.key, required this.item});

  final TodoItem item;

  static Future<void> show(BuildContext context, {required TodoItem item}) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.78;
        return SizedBox(
          height: height,
          child: TodoW9FormSheet(item: item),
        );
      },
    );
  }

  @override
  ConsumerState<TodoW9FormSheet> createState() => _TodoW9FormSheetState();
}

class _TodoW9FormSheetState extends ConsumerState<TodoW9FormSheet> {
  bool _uploading = false;

  TodoItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await ref
            .read(documentTypesStateProvider.notifier)
            .fetchDocumentTypes();
      } catch (_) {
        // Label enrichment is optional; todo/details fallback is enough.
      }
    });
  }

  String _resolveDocumentTypeLabel() {
    final fromTodo = item.w9DocumentTypeLabel.trim();
    if (fromTodo.isNotEmpty && fromTodo != defaultW9DocumentTypeLabel) {
      return fromTodo;
    }

    final options = ref.read(documentTypesStateProvider).data;
    for (final option in options) {
      if (option.key.trim().toUpperCase() == documentTypeW9Key) {
        final label = option.label.trim();
        if (label.isNotEmpty) return label;
      }
    }

    return fromTodo.isNotEmpty ? fromTodo : defaultW9DocumentTypeLabel;
  }

  String? get _categoryReferenceId {
    final fromAuth = ref
        .read(documentsListStateProvider.notifier)
        .resolveAgentProfileIdForUpload();
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;

    final fromTodo = item.agentId?.trim();
    if (fromTodo != null && fromTodo.isNotEmpty) return fromTodo;
    return null;
  }

  Future<void> _downloadBlankForm() async {
    final launched = await launchUrlString(
      w9BlankFormUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (launched) {
      context.showVcareToast(
        title: 'Opening W-9 form',
        variant: VcareToastVariant.success,
      );
    } else {
      context.showVcareToast(
        title: 'Unable to open W-9 form',
        variant: VcareToastVariant.destructive,
      );
    }
  }

  Future<void> _pickAndUploadPdf() async {
    if (_uploading) return;

    final categoryReferenceId = _categoryReferenceId;
    if (categoryReferenceId == null) {
      context.showVcareToast(
        title: 'Agent profile is required to upload documents',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    const pdfGroup = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      uniformTypeIdentifiers: ['com.adobe.pdf'],
      mimeTypes: ['application/pdf'],
    );

    final file = await openFile(acceptedTypeGroups: [pdfGroup]);
    if (!mounted || file == null) return;

    final documentType = _resolveDocumentTypeLabel();
    setState(() => _uploading = true);

    try {
      final bytes = await file.readAsBytes();
      final fileName = file.name.trim().isEmpty ? 'w9.pdf' : file.name;

      await ref.read(documentsListStateProvider.notifier).uploadDocument(
        fileName: fileName,
        bytes: bytes,
        documentType: documentType,
        agentProfileId: categoryReferenceId,
        onCompleted: (success, error) async {
          if (!mounted) return;

          if (!success) {
            setState(() => _uploading = false);
            context.showVcareToast(
              title: error?.trim().isNotEmpty == true
                  ? error!
                  : 'Upload failed',
              variant: VcareToastVariant.destructive,
            );
            return;
          }

          await ref.read(todoListStateProvider.notifier).refresh();
          if (!mounted) return;

          setState(() => _uploading = false);
          context.showVcareToast(
            title: 'Uploaded 1 file',
            variant: VcareToastVariant.success,
          );
          Navigator.of(context).pop();
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      context.showVcareToast(
        title: 'Upload failed',
        variant: VcareToastVariant.destructive,
      );
    }
  }

  void _contactSupport() {
    context.showVcareToast(
      title: 'Contacting support',
      description: "We'll be in touch shortly.",
      variant: VcareToastVariant.info,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Rebuild when document types arrive so step copy can use the API label.
    ref.watch(documentTypesStateProvider);
    final documentType = _resolveDocumentTypeLabel();

    return SafeArea(
      top: false,
      child: Column(
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Text(
              'Complete your W-9',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Divider(height: 1, color: vcare.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (item.description.trim().isNotEmpty) ...[
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: vcare.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _StepCard(
                    step: 1,
                    title: 'Download the blank form',
                    subtitle: 'Opens the official IRS $documentType PDF.',
                    icon: LucideIcons.download,
                    emphasized: false,
                    onTap: _uploading ? null : _downloadBlankForm,
                  ),
                  const SizedBox(height: 12),
                  _StepCard(
                    step: 2,
                    title: 'Fill it out and sign',
                    subtitle:
                        'Complete the form offline, then come back here to upload.',
                    icon: LucideIcons.pencil,
                    emphasized: false,
                    muted: true,
                  ),
                  const SizedBox(height: 12),
                  _StepCard(
                    step: 3,
                    title: 'Upload your signed PDF',
                    subtitle: 'PDF only. We’ll attach it as $documentType.',
                    icon: LucideIcons.upload,
                    emphasized: true,
                    footer: FilledButton(
                      onPressed: _uploading ? null : _pickAndUploadPdf,
                      style: FilledButton.styleFrom(
                        backgroundColor: VCareColors.primary,
                        foregroundColor: VCareColors.primaryForeground,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_uploading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: VCareColors.primaryForeground,
                              ),
                            )
                          else
                            const Icon(LucideIcons.upload, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _uploading
                                ? 'Uploading…'
                                : 'Choose file to upload',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Need help? '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: _uploading ? null : _contactSupport,
                            child: Text(
                              'Contact support',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: VCareColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: vcare.border)),
            ),
            child: OutlinedButton(
              onPressed: _uploading
                  ? null
                  : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emphasized,
    this.muted = false,
    this.onTap,
    this.footer,
  });

  final int step;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool emphasized;
  final bool muted;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final borderColor = emphasized
        ? VCareColors.primary.withValues(alpha: 0.25)
        : vcare.border;
    final background = emphasized
        ? VCareColors.primary.withValues(alpha: 0.05)
        : muted
        ? vcare.muted.withValues(alpha: 0.3)
        : vcare.card;
    final badgeBg = emphasized
        ? VCareColors.primary
        : muted
        ? vcare.muted
        : VCareColors.primary.withValues(alpha: 0.1);
    final badgeFg = emphasized
        ? VCareColors.primaryForeground
        : muted
        ? vcare.mutedForeground
        : VCareColors.primary;
    final iconColor = emphasized
        ? VCareColors.primary
        : vcare.mutedForeground;

    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeFg,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(icon, size: 16, color: iconColor),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}
