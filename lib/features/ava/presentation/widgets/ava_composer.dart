import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/ava/presentation/widgets/ava_layout.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Matches vcareapp [AvaComposer] — `px-5 pt-1 pb-0`, pill input + send.
class AvaComposer extends StatelessWidget {
  const AvaComposer({
    super.key,
    required this.controller,
    required this.editingId,
    required this.canSend,
    required this.onSend,
    required this.onCancelEdit,
  });

  static const double _fieldPaddingLeft = 16;
  static const double _fieldPaddingRight = 6;
  static const double _sendButtonSize = 36;
  static const double _textSize = 14;

  final TextEditingController controller;
  final String? editingId;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomPadding = context.mobileShellBottomContentPadding;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AvaLayout.horizontalPadding,
          8,
          AvaLayout.horizontalPadding,
          bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (editingId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: vcare.muted.withValues(alpha: 0.6),
                  borderRadius: VCareRadius.mdAll,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Editing message',
                        style: TextStyle(
                          fontSize: 11,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelEdit,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.vcare.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Material(
              color: vcare.card,
              shape: RoundedRectangleBorder(
                borderRadius: VCareRadius.fullAll,
                side: BorderSide(color: vcare.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _fieldPaddingLeft,
                  6,
                  _fieldPaddingRight,
                  6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(
                          fontSize: _textSize,
                          height: 1.25,
                        ),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: canSend ? (_) => onSend() : null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          hintText: 'Ask AVA anything…',
                          hintStyle: TextStyle(
                            fontSize: _textSize,
                            color: vcare.mutedForeground.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: canSend
                          ? context.vcare.primary
                          : context.vcare.primary.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: canSend ? onSend : null,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: _sendButtonSize,
                          height: _sendButtonSize,
                          child: Icon(
                            LucideIcons.send,
                            size: 16,
                            color: context.theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
