import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/help_support/domain/entities/contact_support_attachment.dart';
import 'package:vcare_admin/features/help_support/presentation/providers/help_support_state_provider.dart';
import 'package:vcare_admin/features/help_support/utils/help_support_constants.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// parity: vcare-agent-app-2.0/src/features/help-support/components/ContactSupportDialog.tsx
class ContactSupportSheet extends ConsumerStatefulWidget {
  const ContactSupportSheet({super.key, this.subject, this.contextPayload});

  /// Folded into `context.subject` for the email subject line.
  final String? subject;

  /// Flat metadata included with the request (not shown in UI).
  final Map<String, Object?>? contextPayload;

  static Future<void> show(
    BuildContext context, {
    String? subject,
    Map<String, Object?>? contextPayload,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.85;
        return SizedBox(
          height: height,
          child: ContactSupportSheet(
            subject: subject,
            contextPayload: contextPayload,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<ContactSupportSheet> createState() =>
      _ContactSupportSheetState();
}

class _ContactSupportSheetState extends ConsumerState<ContactSupportSheet> {
  final _messageController = TextEditingController();
  final _files = <ContactSupportAttachment>[];
  var _picking = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Map<String, Object?> _mergedContext() {
    final next = <String, Object?>{
      if (widget.contextPayload != null) ...widget.contextPayload!,
    };
    final subject = widget.subject?.trim();
    if (subject != null && subject.isNotEmpty) {
      next['subject'] = subject;
    }
    return next;
  }

  Future<void> _pickFiles() async {
    if (_picking || _files.length >= contactSupportMaxFiles) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.pickFiles();
      if (!mounted || result == null) return;

      final remaining = contactSupportMaxFiles - _files.length;
      final selected = result.files
          .where((file) => (file.path ?? '').trim().isNotEmpty)
          .take(remaining)
          .map(
            (file) => ContactSupportAttachment(
              path: file.path!.trim(),
              fileName: file.name,
            ),
          )
          .toList();

      if (result.files.length > remaining) {
        context.showVcareToast(
          title: 'You can attach up to $contactSupportMaxFiles files',
          variant: VcareToastVariant.destructive,
        );
      }

      if (selected.isEmpty) return;
      setState(() => _files.addAll(selected));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < contactSupportMinMessageLength) return;

    final merged = _mergedContext();
    await ref
        .read(helpSupportStateProvider.notifier)
        .submitContactSupport(
          message: message,
          context: merged.isEmpty ? null : merged,
          files: List<ContactSupportAttachment>.from(_files),
          onCompleted: (result) {
            if (!mounted) return;
            if (result == null) {
              final error = ref.read(helpSupportStateProvider).error;
              context.showVcareToast(
                title: error?.trim().isNotEmpty == true
                    ? error!
                    : 'Could not send support request',
                variant: VcareToastVariant.destructive,
              );
              return;
            }
            context.showVcareToast(
              title: 'Message received!',
              description: 'We will reply to you soon.',
              variant: VcareToastVariant.success,
            );
            ref.read(helpSupportStateProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final submitting = ref.watch(helpSupportStateProvider).submitting;
    final messageTrimmed = _messageController.text.trim();
    final canSubmit =
        messageTrimmed.length >= contactSupportMinMessageLength && !submitting;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(VCareLayout.sheetTopRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
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
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'How can we help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                "Send us a message and we'll get back to you soon.",
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: vcare.mutedForeground,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Text(
                    "What's going on? Share as much detail as you can — "
                    'it helps us help you faster.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: VCareColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    enabled: !submitting,
                    minLines: 5,
                    maxLines: 8,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Describe the issue or question…',
                      filled: true,
                      fillColor: vcare.muted.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: vcare.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: vcare.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: VCareColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add screenshots or files (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: VCareColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed:
                          submitting ||
                              _picking ||
                              _files.length >= contactSupportMaxFiles
                          ? null
                          : _pickFiles,
                      icon: const Icon(LucideIcons.paperclip, size: 16),
                      label: const Text('Add files'),
                    ),
                  ),
                  if (_files.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (var i = 0; i < _files.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: vcare.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _files[i].fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              IconButton(
                                onPressed: submitting
                                    ? null
                                    : () => setState(() => _files.removeAt(i)),
                                icon: Icon(
                                  LucideIcons.x,
                                  size: 14,
                                  color: vcare.mutedForeground,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  child: Text(submitting ? 'Sending…' : 'Send message'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
