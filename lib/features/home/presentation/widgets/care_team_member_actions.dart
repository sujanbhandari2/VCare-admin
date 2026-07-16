import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';

class CareTeamMemberActions extends StatelessWidget {
  const CareTeamMemberActions({super.key, required this.member});

  final CareTeamMember member;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isOrg = member.isOrg;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: vcare.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.phone,
              label: 'Call',
              onTap: member.phone == null
                  ? null
                  : () => launchUrlString('tel:${member.phone}'),
            ),
          ),
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.mail,
              label: 'Email',
              showLeftBorder: !isOrg,
              showRightBorder: !isOrg,
              onTap: member.email == null
                  ? null
                  : () => launchUrlString('mailto:${member.email}'),
            ),
          ),
          if (!isOrg)
            Expanded(
              child: _ActionButton(
                icon: LucideIcons.messageCircle,
                label: 'Message',
                onTap: () => context.pushNamed(
                  AppRouter.careTeamDetailName,
                  pathParameters: {'id': member.id},
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.showLeftBorder = false,
    this.showRightBorder = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showLeftBorder;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: showLeftBorder
                  ? BorderSide(color: vcare.border)
                  : BorderSide.none,
              right: showRightBorder
                  ? BorderSide(color: vcare.border)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
