import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/ava/domain/entities/ava_message.dart';
import 'package:vcare_admin/features/ava/presentation/widgets/ava_layout.dart';
import 'package:vcare_admin/features/ava/presentation/widgets/ava_message_actions_menu.dart';

/// Matches vcareapp [AvaChatMessage].
class AvaMessageBubble extends StatelessWidget {
  const AvaMessageBubble({
    super.key,
    required this.message,
    this.onEdit,
    this.onDelete,
  });

  final AvaMessage message;
  final void Function(String id, String body)? onEdit;
  final void Function(String id)? onDelete;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isMe = message.isMe;
    final maxBubbleWidth =
        MediaQuery.sizeOf(context).width * AvaLayout.bubbleMaxWidthFactor;

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[_AvaAvatar(vcare: vcare), const SizedBox(width: 8)],
        if (isMe && (onEdit != null || onDelete != null)) ...[
          AvaMessageActionsMenu(
            onEdit: onEdit != null
                ? () => onEdit!(message.id, message.body)
                : null,
            onDelete: onDelete != null ? () => onDelete!(message.id) : null,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            padding: AvaLayout.bubblePadding,
            decoration: BoxDecoration(
              color: isMe ? VCareColors.primary : vcare.muted,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AvaLayout.bubbleRadius),
                topRight: const Radius.circular(AvaLayout.bubbleRadius),
                bottomLeft: Radius.circular(
                  isMe ? AvaLayout.bubbleRadius : AvaLayout.bubbleTailRadius,
                ),
                bottomRight: Radius.circular(
                  isMe ? AvaLayout.bubbleTailRadius : AvaLayout.bubbleRadius,
                ),
              ),
            ),
            child: Text(
              message.body,
              style: TextStyle(
                fontSize: AvaLayout.bubbleFontSize,
                height: 1.35,
                color: isMe
                    ? VCareColors.primaryForeground
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvaAvatar extends StatelessWidget {
  const _AvaAvatar({required this.vcare});

  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AvaLayout.avatarSize,
      height: AvaLayout.avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [VCareColors.primary, vcare.accent],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        LucideIcons.sparkles,
        size: AvaLayout.avatarIconSize,
        color: VCareColors.primaryForeground,
      ),
    );
  }
}
