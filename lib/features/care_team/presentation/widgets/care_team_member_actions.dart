import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class CareTeamMemberActions extends StatelessWidget {
  const CareTeamMemberActions({
    super.key,
    required this.member,
    this.variant = CareTeamMemberActionsVariant.footer,
    this.onDelete,
    this.isDeleting = false,
  });

  final CareTeamMember member;
  final CareTeamMemberActionsVariant variant;
  final VoidCallback? onDelete;
  final bool isDeleting;

  void _onCall(BuildContext context) {
    final phone = member.phone?.trim();
    if (phone == null || phone.isEmpty) {
      context.showVcareToast(
        title: 'No phone number',
        description: 'This contact has no phone number on file.',
      );
      return;
    }
    launchUrlString('tel:$phone');
  }

  void _onEmail(BuildContext context) {
    final email = member.email?.trim();
    if (email == null || email.isEmpty) {
      context.showVcareToast(
        title: 'No email address',
        description: 'This contact has no email on file.',
      );
      return;
    }
    launchUrlString('mailto:$email');
  }

  void _onMessage(BuildContext context) {
    final userId = member.userId?.trim();
    if (userId == null || userId.isEmpty) return;
    context.goNamed(
      AppRouter.messages.toPathName,
      queryParameters: {'userId': userId},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (variant == CareTeamMemberActionsVariant.inline) {
      return _InlineActions(
        member: member,
        isDeleting: isDeleting,
        onCall: () => _onCall(context),
        onEmail: () => _onEmail(context),
        onMessage: member.canMessage ? () => _onMessage(context) : null,
        onDelete: onDelete,
      );
    }

    final canMessage = member.canMessage;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.vcare.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FooterActionButton(
              icon: LucideIcons.mail,
              label: 'Email',
              onTap: () => _onEmail(context),
              enabled: member.email?.trim().isNotEmpty == true,
            ),
          ),
          if (canMessage)
            Expanded(
              child: _FooterActionButton(
                icon: LucideIcons.messageSquare,
                label: 'Message',
                showLeftBorder: true,
                onTap: () => _onMessage(context),
                enabled: true,
              ),
            ),
          Expanded(
            child: _FooterActionButton(
              icon: LucideIcons.phone,
              label: 'Call',
              showLeftBorder: true,
              onTap: () => _onCall(context),
              enabled: member.phone?.trim().isNotEmpty == true,
            ),
          ),
        ],
      ),
    );
  }
}

enum CareTeamMemberActionsVariant { footer, inline }

class _InlineActions extends StatelessWidget {
  const _InlineActions({
    required this.member,
    required this.isDeleting,
    required this.onCall,
    required this.onEmail,
    this.onMessage,
    this.onDelete,
  });

  final CareTeamMember member;
  final bool isDeleting;
  final VoidCallback onCall;
  final VoidCallback onEmail;
  final VoidCallback? onMessage;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final hasEmail = member.email?.trim().isNotEmpty == true;
    final hasPhone = member.phone?.trim().isNotEmpty == true;
    final showManage = onDelete != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconAction(
          icon: LucideIcons.mail,
          tooltip: 'Email ${member.name}',
          enabled: hasEmail,
          onTap: onEmail,
        ),
        if (onMessage != null)
          _IconAction(
            icon: LucideIcons.messageSquare,
            tooltip: 'Message',
            enabled: true,
            onTap: onMessage!,
          ),
        _IconAction(
          icon: LucideIcons.phone,
          tooltip: 'Call ${member.name}',
          enabled: hasPhone,
          emphasized: true,
          onTap: onCall,
        ),
        if (showManage)
          PopupMenuButton<String>(
            enabled: !isDeleting,
            tooltip: 'More options for ${member.name}',
            padding: EdgeInsets.zero,
            icon: Icon(
              LucideIcons.moreHorizontal,
              size: 18,
              color: vcare.mutedForeground,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                context.pushNamed(
                  AppRouter.careTeamEditName,
                  pathParameters: {'id': member.id},
                );
              } else if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(LucideIcons.pencil, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                enabled: !isDeleting,
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final child = IconButton(
      onPressed: enabled ? onTap : null,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 18,
        color: emphasized
            ? Theme.of(context).colorScheme.primary
            : vcare.mutedForeground,
      ),
      style: emphasized
          ? IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            )
          : null,
    );
    return Opacity(opacity: enabled ? 1 : 0.4, child: child);
  }
}

class _FooterActionButton extends StatelessWidget {
  const _FooterActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
    this.showLeftBorder = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool showLeftBorder;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                left: showLeftBorder
                    ? BorderSide(color: vcare.border)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
