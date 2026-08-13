import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/presentation/providers/document_types_state_provider.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_floating_bottom_sheet.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Bottom sheet that loads document types and returns the selected **label**.
class DocumentsTypePickerSheet extends ConsumerStatefulWidget {
  const DocumentsTypePickerSheet({
    super.key,
    required this.includeW9,
  });

  final bool includeW9;

  static Future<String?> show(
    BuildContext context, {
    required bool includeW9,
  }) {
    return context.showBottomSheet<String>(
      maxHeightFactor: 0.55,
      margin: vcareCompactBottomSheetMargin(context),
      builder: (sheetContext) => DocumentsTypePickerSheet(includeW9: includeW9),
    );
  }

  @override
  ConsumerState<DocumentsTypePickerSheet> createState() =>
      _DocumentsTypePickerSheetState();
}

class _DocumentsTypePickerSheetState
    extends ConsumerState<DocumentsTypePickerSheet> {
  String? _selectedLabel;
  bool _didRequestFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didRequestFetch) return;
      _didRequestFetch = true;
      ref.read(documentTypesStateProvider.notifier).fetchDocumentTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final typesState = ref.watch(documentTypesStateProvider);
    final options = filterDocumentTypeOptions(
      typesState.data,
      includeW9: widget.includeW9,
    );

    ref.listen(documentTypesStateProvider, (previous, next) {
      final nextOptions = filterDocumentTypeOptions(
        next.data,
        includeW9: widget.includeW9,
      );
      if (nextOptions.isEmpty) return;
      final current = _selectedLabel;
      final stillValid =
          current != null &&
          nextOptions.any((option) => option.label == current);
      if (stillValid) return;
      setState(() {
        _selectedLabel = defaultDocumentTypeLabelFrom(nextOptions);
      });
    });

    final selected = () {
      final current = _selectedLabel;
      if (current != null &&
          options.any((option) => option.label == current)) {
        return current;
      }
      if (options.isEmpty) return null;
      return defaultDocumentTypeLabelFrom(options);
    }();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Document type',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a type, then select files to upload.',
            style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
          ),
          const SizedBox(height: 12),
          if (typesState.requesting && options.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (typesState.hasError && options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                typesState.error ?? 'Failed to load document types',
                style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
              ),
            )
          else if (options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No document types',
                style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
              ),
            )
          else
            Flexible(
              child: RadioGroup<String>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedLabel = value);
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return RadioListTile<String>(
                      value: option.label,
                      title: Text(
                        option.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: selected == null || selected.isEmpty
                ? null
                : () => Navigator.of(context).pop(selected),
            style: FilledButton.styleFrom(
              backgroundColor: context.vcare.primary,
              foregroundColor: context.theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: VCareRadius.lgAll,
              ),
            ),
            child: const Text('Choose files'),
          ),
        ],
      ),
    );
  }
}
