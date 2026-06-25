import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_cases_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

class ClientCreateCaseSheet extends ConsumerStatefulWidget {
  const ClientCreateCaseSheet({super.key, required this.clientId});

  final String clientId;

  static Future<void> show(BuildContext context, {required String clientId}) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ClientCreateCaseSheet(clientId: clientId),
        );
      },
    );
  }

  @override
  ConsumerState<ClientCreateCaseSheet> createState() =>
      _ClientCreateCaseSheetState();
}

class _ClientCreateCaseSheetState extends ConsumerState<ClientCreateCaseSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final description = _descriptionController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSubmitting = true);

    await ref
        .read(clientCasesStateProvider(widget.clientId).notifier)
        .createCase(
          title: title,
          description: description,
          onCompleted: (success, error) {
            if (!mounted) return;

            if (success) {
              context.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Request created.')),
              );
              return;
            }

            setState(() => _isSubmitting = false);
            messenger.showSnackBar(
              SnackBar(content: Text(error ?? 'Unable to create request.')),
            );
          },
        );

    if (!mounted || !_isSubmitting) return;
    setState(() => _isSubmitting = false);
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Create new request',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldLabel('Request title'),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. Claim denial appeal',
                    filled: true,
                    fillColor: vcare.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: vcare.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: vcare.border),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _FieldLabel('Description'),
                const SizedBox(height: 6),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add context for this request…',
                    filled: true,
                    fillColor: vcare.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: vcare.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: vcare.border),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton.elevated(
                  onPressed: _isSubmitting ? null : _submit,
                  text: 'Create request',
                  loading: _isSubmitting,
                  color: VCareColors.primary,
                  onButtonColor: VCareColors.primaryForeground,
                  height: 44,
                  borderRadius: BorderRadius.circular(12),
                  fontSize: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: vcare.mutedForeground,
      ),
    );
  }
}
