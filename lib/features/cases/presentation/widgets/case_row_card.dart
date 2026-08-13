import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_status_chip.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';

class CaseRowCard extends StatelessWidget {
  const CaseRowCard({
    super.key,
    required this.referralCase,
    this.onTap,
    this.onToggleBookmark,
  });

  final ReferralCase referralCase;
  final VoidCallback? onTap;
  final VoidCallback? onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final clientName = truncateWords(referralCase.client.displayName, 3);
    final caseType = resolveCaseTypeLabel(referralCase.caseType);
    final created = formatCaseListDate(referralCase.createdAt);
    final assignee = referralCase.assignedTo.trim().isEmpty
        ? 'Unassigned'
        : referralCase.assignedTo.trim();
    final metaParts = <String>[
      assignee,
      if (created.isNotEmpty) created,
    ];

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: VCareColors.cardTint,
          borderRadius: VCareRadius.xlAll,
          border: Border.all(color: VCareColors.cardTintBorder),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ClientInitialsAvatar(
                      initials: referralCase.client.initials,
                      vcare: vcare,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName.isEmpty ? 'Unknown client' : clientName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#${formatCaseIdShort(referralCase.id.isNotEmpty ? referralCase.id : referralCase.caseNumber)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: vcare.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleBookmark,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      tooltip: referralCase.isBookmarked
                          ? 'Remove bookmark'
                          : 'Bookmark case',
                      icon: Icon(
                        referralCase.isBookmarked
                            ? Icons.bookmark
                            : LucideIcons.bookmark,
                        size: 18,
                        color: referralCase.isBookmarked
                            ? context.vcare.primary
                            : vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (caseType.isNotEmpty) _OutlineTypeChip(label: caseType),
                    CaseStatusChip(status: referralCase.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  metaParts.join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: vcare.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientInitialsAvatar extends StatelessWidget {
  const _ClientInitialsAvatar({required this.initials, required this.vcare});

  final String initials;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.vcare.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: vcare.border),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.vcare.primary,
        ),
      ),
    );
  }
}

class _OutlineTypeChip extends StatelessWidget {
  const _OutlineTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: VCareRadius.fullAll,
        border: Border.all(color: vcare.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
