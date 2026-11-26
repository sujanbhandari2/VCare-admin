import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/utils/file_name.dart';

/// Prompt for a clear file name before attach/upload (client RequestFileNamePromptDialog).
class UploadFileNamePromptDialog extends StatefulWidget {
  const UploadFileNamePromptDialog({
    super.key,
    required this.defaultName,
    this.title = 'Name this file',
    this.description =
        'Choose a clear name so your advocate can find it easily. The extension cannot be changed.',
    this.validateWithDocumentRules = true,
  });

  final String defaultName;
  final String title;
  final String description;

  /// When true, Save also runs [documentRenameValidationError].
  final bool validateWithDocumentRules;

  /// Returns the chosen full file name, or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String defaultName,
    String title = 'Name this file',
    String description =
        'Choose a clear name so your advocate can find it easily. The extension cannot be changed.',
    bool validateWithDocumentRules = true,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => UploadFileNamePromptDialog(
        defaultName: defaultName,
        title: title,
        description: description,
        validateWithDocumentRules: validateWithDocumentRules,
      ),
    );
  }

  @override
  State<UploadFileNamePromptDialog> createState() =>
      _UploadFileNamePromptDialogState();
}

class _UploadFileNamePromptDialogState
    extends State<UploadFileNamePromptDialog> {
  late final TextEditingController _controller;
  late final String _extension;
  String? _error;

  @override
  void initState() {
    super.initState();
    final parts = splitFileName(widget.defaultName);
    _extension = parts.extension;
    _controller = TextEditingController(text: parts.baseName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final next = joinFileName(_controller.text, _extension);
    if (next.isEmpty) return;

    if (widget.validateWithDocumentRules) {
      final error = documentRenameValidationError(next);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
    }

    Navigator.of(context).pop(next);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final canSave = _controller.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 14,
              color: vcare.mutedForeground,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: 200,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[\\/:*?"<>|]')),
                  ],
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() => _error = null);
                    } else {
                      setState(() {});
                    }
                  },
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'File name',
                    counterText: '',
                    errorText: _error,
                  ),
                ),
              ),
              if (_extension.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: vcare.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: vcare.border),
                  ),
                  child: Text(
                    _extension,
                    style: TextStyle(
                      fontSize: 14,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: VCareColors.primary,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
