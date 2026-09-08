import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';

const caseCreateFieldRadius = 12.0;

InputDecoration caseCreateInputDecoration(
  BuildContext context, {
  required String hint,
  IconData? prefixIcon,
  Widget? suffix,
}) {
  final vcare = context.vcare;
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: vcare.card,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 18, color: vcare.mutedForeground),
    suffixIcon: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(caseCreateFieldRadius),
      borderSide: BorderSide(color: vcare.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(caseCreateFieldRadius),
      borderSide: BorderSide(color: vcare.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(caseCreateFieldRadius),
      borderSide: BorderSide(color: context.vcare.primary, width: 1.5),
    ),
  );
}

class CaseCreateSearchResultTile extends StatelessWidget {
  const CaseCreateSearchResultTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle = '',
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: vcare.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaseCreateSelectedClientCard extends StatelessWidget {
  const CaseCreateSelectedClientCard({
    super.key,
    required this.client,
    this.onChange,
  });

  final CaseCreationClient client;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final subtitle = [
      if (client.email.trim().isNotEmpty) client.email.trim(),
      if (client.phone.trim().isNotEmpty) client.phone.trim(),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: context.vcare.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: context.vcare.primary.withValues(alpha: 0.12),
            child: Icon(LucideIcons.user, size: 18, color: context.vcare.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onChange != null)
            TextButton(
              onPressed: onChange,
              child: const Text('Change'),
            ),
        ],
      ),
    );
  }
}

class CaseCreateSelectedAssigneeCard extends StatelessWidget {
  const CaseCreateSelectedAssigneeCard({
    super.key,
    required this.assignee,
    required this.onClear,
  });

  final CaseAssignee assignee;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final subtitle = [
      if (assignee.role.trim().isNotEmpty) assignee.role.trim(),
      if (assignee.email.trim().isNotEmpty) assignee.email.trim(),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: context.vcare.primary.withValues(alpha: 0.12),
            child: Text(
              assignee.initials,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.vcare.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignee.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            tooltip: 'Clear assignee',
            icon: Icon(LucideIcons.x, size: 18, color: vcare.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class CaseCreateTypeChip extends StatelessWidget {
  const CaseCreateTypeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: selected
          ? context.vcare.primary.withValues(alpha: 0.12)
          : vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.fullAll,
        side: BorderSide(
          color: selected
              ? context.vcare.primary.withValues(alpha: 0.55)
              : vcare.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.fullAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(LucideIcons.check, size: 14, color: context.vcare.primary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? context.vcare.primary
                      : context.vcare.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
