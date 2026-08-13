import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_file.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_files_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_add_file_sheet.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_file_row.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Files tab for case detail.
class CaseFilesTab extends ConsumerWidget {
  const CaseFilesTab({
    super.key,
    required this.caseId,
    required this.clientId,
  });

  final String caseId;
  final String clientId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CaseFile file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete file?'),
        content: const Text(
          'This file will be removed from the case. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(caseFilesStateProvider(caseId).notifier)
        .deleteFile(
          fileId: file.id,
          onCompleted: (success, error) {
            if (!context.mounted) return;
            context.showVcareToast(
              title: success
                  ? 'File deleted'
                  : (error ?? 'Failed to delete file'),
              variant: success
                  ? VcareToastVariant.success
                  : VcareToastVariant.destructive,
            );
          },
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(caseFilesStateProvider(caseId));

    return ListView(
      physics: VcareRefreshScrollView.physics,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        context.mobileShellBottomContentPadding,
      ),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: state.mutating
                ? null
                : () => CaseAddFileSheet.show(
                    context,
                    caseId: caseId,
                    clientId: clientId,
                  ),
            icon: state.mutating
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.plus, size: 14),
            label: Text(state.mutating ? 'Uploading...' : 'Upload File'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.vcare.mutedForeground,
              side: BorderSide(color: context.vcare.border),
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: VCareRadius.mdAll),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (state.isInitialLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null && state.files.isEmpty)
          VcareInlineErrorCard(
            message: state.error,
            onRetry: () =>
                ref.read(caseFilesStateProvider(caseId).notifier).fetchFiles(),
          )
        else if (state.files.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.folderOpen,
            title: 'No files attached yet',
            description: 'Upload documents related to this case.',
          )
        else
          for (var i = 0; i < state.files.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            CaseFileRow(
              file: state.files[i],
              onDelete: () => _confirmDelete(context, ref, state.files[i]),
            ),
          ],
      ],
    );
  }
}
