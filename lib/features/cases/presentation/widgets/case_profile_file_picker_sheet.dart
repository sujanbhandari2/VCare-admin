import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_file.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_files_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_profile_files_state_provider.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Attaches existing client profile files to the case, mirroring the web
/// `ProfileFilePicker`.
class CaseProfileFilePickerSheet extends ConsumerStatefulWidget {
  const CaseProfileFilePickerSheet({
    super.key,
    required this.caseId,
    required this.clientId,
  });

  final String caseId;
  final String clientId;

  @override
  ConsumerState<CaseProfileFilePickerSheet> createState() =>
      _CaseProfileFilePickerSheetState();
}

class _CaseProfileFilePickerSheetState
    extends ConsumerState<CaseProfileFilePickerSheet> {
  final _selectedIds = <String>{};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(caseProfileFilesStateProvider(widget.clientId).notifier)
          .fetchFiles();
    });
  }

  /// Files already on the case are matched by URL, as the web picker does.
  List<CaseFile> _selectableFiles(List<CaseFile> profileFiles) {
    final attachedUrls = ref
        .read(caseFilesStateProvider(widget.caseId))
        .files
        .map((file) => file.url?.trim())
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toSet();

    return profileFiles
        .where((file) => !attachedUrls.contains(file.url?.trim()))
        .toList(growable: false);
  }

  Future<void> _submit(List<CaseFile> selectable) async {
    if (_submitting || _selectedIds.isEmpty) return;

    final selected = selectable
        .where((file) => _selectedIds.contains(file.id))
        .toList(growable: false);
    if (selected.isEmpty) return;

    setState(() => _submitting = true);

    await ref
        .read(caseFilesStateProvider(widget.caseId).notifier)
        .attachProfileFiles(
          clientId: widget.clientId,
          files: selected,
          onCompleted: (success, error) {
            if (!mounted) return;
            if (success) {
              context.showVcareToast(
                title: selected.length == 1
                    ? 'Profile file attached'
                    : '${selected.length} profile files attached',
                variant: VcareToastVariant.success,
              );
              context.pop();
              return;
            }
            setState(() => _submitting = false);
            context.showVcareToast(
              title: error ?? 'Failed to attach profile files',
              variant: VcareToastVariant.destructive,
            );
          },
        );

    if (mounted && _submitting) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final state = ref.watch(caseProfileFilesStateProvider(widget.clientId));
    final selectable = _selectableFiles(state.files);
    final hasClient = widget.clientId.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'From Profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Attach documents already stored on the client profile.',
              style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
            ),
            const SizedBox(height: 12),
            if (!hasClient)
              _PickerMessage(text: 'No client linked')
            else if (state.isInitialLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && state.files.isEmpty)
              VcareInlineErrorCard(
                message: state.error,
                onRetry: () => ref
                    .read(
                      caseProfileFilesStateProvider(widget.clientId).notifier,
                    )
                    .fetchFiles(),
              )
            else if (state.files.isEmpty)
              _PickerMessage(text: 'No profile files available')
            else if (selectable.isEmpty)
              _PickerMessage(text: 'All profile files are already attached')
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: selectable.length,
                  itemBuilder: (context, index) {
                    final file = selectable[index];
                    final selected = _selectedIds.contains(file.id);

                    return CheckboxListTile(
                      value: selected,
                      onChanged: _submitting
                          ? null
                          : (checked) => setState(() {
                              if (checked ?? false) {
                                _selectedIds.add(file.id);
                              } else {
                                _selectedIds.remove(file.id);
                              }
                            }),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: VCareRadius.lgAll,
                      ),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: file.uploadedAt.trim().isEmpty
                          ? null
                          : Text(
                              formatCaseListDate(file.uploadedAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: vcare.mutedForeground,
                              ),
                            ),
                      secondary: Icon(
                        LucideIcons.fileText,
                        size: 16,
                        color: vcare.mutedForeground,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            AppButton.elevated(
              text: 'Save',
              loading: _submitting,
              onPressed: _submitting || _selectedIds.isEmpty
                  ? null
                  : () => _submit(selectable),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerMessage extends StatelessWidget {
  const _PickerMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: context.vcare.mutedForeground,
          ),
        ),
      ),
    );
  }
}
