import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_files_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_profile_file_picker_sheet.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Add-file sheet: Device, URL, and Coming soon (client profile).
class CaseAddFileSheet extends StatelessWidget {
  const CaseAddFileSheet({
    super.key,
    required this.caseId,
    required this.clientId,
    required this.hostContext,
  });

  final String caseId;
  final String clientId;
  final BuildContext hostContext;

  static Future<void> show(
    BuildContext context, {
    required String caseId,
    required String clientId,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => CaseAddFileSheet(
        caseId: caseId,
        clientId: clientId,
        hostContext: context,
      ),
    );
  }

  static Future<void> _pickDeviceFiles(
    ProviderContainer container,
    String caseId,
    String clientId,
    BuildContext context,
  ) async {
    final typeGroup = XTypeGroup(
      label: 'Files',
      extensions: caseAllowedFileExtensions.toList(growable: false),
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty || !context.mounted) return;

    if (files.length > caseFileMaxCount) {
      context.showVcareToast(
        title: 'You can upload up to $caseFileMaxCount files at a time',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    final payloads = <({String fileName, List<int> bytes})>[];
    var totalBytes = 0;

    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;

      if (bytes.length > caseFileMaxSizeBytes) {
        context.showVcareToast(
          title: '${file.name} is larger than 25MB',
          variant: VcareToastVariant.destructive,
        );
        continue;
      }

      totalBytes += bytes.length;
      if (totalBytes > caseFileMaxBatchBytes) {
        context.showVcareToast(
          title: 'Selected files exceed the 25MB total limit',
          variant: VcareToastVariant.destructive,
        );
        return;
      }

      payloads.add((fileName: file.name, bytes: bytes));
    }
    if (payloads.isEmpty || !context.mounted) return;

    await container
        .read(caseFilesStateProvider(caseId).notifier)
        .uploadFiles(
          clientId: clientId,
          files: payloads,
          onCompleted: (success, error) {
            if (!context.mounted) return;
            context.showVcareToast(
              title: success
                  ? (payloads.length == 1
                        ? 'File uploaded'
                        : '${payloads.length} files uploaded')
                  : (error ?? 'Failed to upload files'),
              variant: success
                  ? VcareToastVariant.success
                  : VcareToastVariant.destructive,
            );
          },
        );
  }

  static Future<void> _showUrlSheet(
    ProviderContainer container,
    String caseId,
    String clientId,
    BuildContext context,
  ) async {
    await context.showBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CaseAddUrlSheet(
        caseId: caseId,
        clientId: clientId,
        container: container,
      ),
    );
  }

  static Future<void> _showProfileSheet(
    ProviderContainer container,
    String caseId,
    String clientId,
    BuildContext context,
  ) async {
    await context.showBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CaseProfileFilePickerSheet(
        caseId: caseId,
        clientId: clientId,
      ),
    );
  }

  void _onOptionSelected({
    required BuildContext sheetContext,
    required Future<void> Function(
      ProviderContainer container,
      String caseId,
      String clientId,
      BuildContext context,
    )
    action,
  }) {
    final container = ProviderScope.containerOf(hostContext);
    sheetContext.pop();
    Future<void>.delayed(const Duration(milliseconds: 225), () {
      if (!hostContext.mounted) return;
      action(container, caseId, clientId, hostContext);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
            child: Text(
              'Add files',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Attach documents from your computer, profile, or a public link.',
              style: TextStyle(
                fontSize: 12,
                color: context.vcare.mutedForeground,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
            child: Column(
              children: [
                _UploadOption(
                  icon: LucideIcons.laptop,
                  label: 'From Computer',
                  onTap: () => _onOptionSelected(
                    sheetContext: context,
                    action: _pickDeviceFiles,
                  ),
                ),
                _UploadOption(
                  icon: LucideIcons.userSquare,
                  label: 'From Profile',
                  onTap: () => _onOptionSelected(
                    sheetContext: context,
                    action: _showProfileSheet,
                  ),
                ),
                _UploadOption(
                  icon: LucideIcons.link2,
                  label: 'From URL',
                  onTap: () => _onOptionSelected(
                    sheetContext: context,
                    action: _showUrlSheet,
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

class _CaseAddUrlSheet extends StatefulWidget {
  const _CaseAddUrlSheet({
    required this.caseId,
    required this.clientId,
    required this.container,
  });

  final String caseId;
  final String clientId;
  final ProviderContainer container;

  @override
  State<_CaseAddUrlSheet> createState() => _CaseAddUrlSheetState();
}

class _CaseAddUrlSheetState extends State<_CaseAddUrlSheet> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _staged = <CaseNotePublicUrl>[];
  bool _submitting = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _stageLink() {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) return;

    // Web `normalizeFileUrl` assumes https when no scheme is supplied.
    final url = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : 'https://$raw';
    if (!url.isUrl) {
      context.showVcareToast(
        title: 'Enter a valid URL',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    final name = _nameController.text.trim();
    setState(() {
      _staged.add(
        CaseNotePublicUrl(url: url, name: name.isEmpty ? url : name),
      );
      _urlController.clear();
      _nameController.clear();
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_staged.isEmpty) {
      _stageLink();
      if (_staged.isEmpty) return;
    }

    final links = List<CaseNotePublicUrl>.from(_staged);
    setState(() => _submitting = true);

    await widget.container
        .read(caseFilesStateProvider(widget.caseId).notifier)
        .addFromUrl(
          clientId: widget.clientId,
          urls: links,
          onCompleted: (success, error) {
            if (!mounted) return;
            if (success) {
              context.showVcareToast(
                title: links.length == 1 ? 'Link added' : 'Links added',
                variant: VcareToastVariant.success,
              );
              context.pop();
              return;
            }
            setState(() => _submitting = false);
            context.showVcareToast(
              title: error ?? 'Unable to add link',
              variant: VcareToastVariant.destructive,
            );
          },
        );
    if (mounted && _submitting) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add from URL',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'File URL',
                hintText: 'https://…',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _submitting ? null : _stageLink,
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text('Add another link'),
              ),
            ),
            if (_staged.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (var i = 0; i < _staged.length; i++)
                _StagedLinkRow(
                  link: _staged[i],
                  onRemove: _submitting
                      ? null
                      : () => setState(() => _staged.removeAt(i)),
                ),
            ],
            const SizedBox(height: 16),
            AppButton.elevated(
              text: 'Save',
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _StagedLinkRow extends StatelessWidget {
  const _StagedLinkRow({required this.link, this.onRemove});

  final CaseNotePublicUrl link;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.link2, size: 14, color: vcare.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              link.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(LucideIcons.x, size: 14),
            color: vcare.mutedForeground,
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
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
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
