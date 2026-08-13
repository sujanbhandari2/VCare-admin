import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_detail_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_assignee_picker_sheet.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Web-style dropdown pills for the case detail header.
class CaseDetailHeader extends ConsumerWidget {
  const CaseDetailHeader({
    super.key,
    required this.caseId,
    required this.caseData,
  });

  final String caseId;
  final ReferralCase caseData;

  static const _statusOptions = <(CaseStatus, String)>[
    (CaseStatus.newCase, 'New'),
    (CaseStatus.requested, 'Requested'),
    (CaseStatus.inProgress, 'In Progress'),
    (CaseStatus.closed, 'Closed'),
  ];

  Future<void> _copyCaseId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: caseData.id));
    if (!context.mounted) return;
    context.showVcareToast(
      title: 'Case ID copied',
      variant: VcareToastVariant.success,
    );
  }

  Future<void> _updateType(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    await ref
        .read(caseDetailStateProvider(caseId).notifier)
        .updateCase(
          type: type,
          onCompleted: (success, error) {
            if (!context.mounted) return;
            if (!success) {
              context.showVcareToast(
                title: error ?? 'Unable to update type',
                variant: VcareToastVariant.destructive,
              );
            }
          },
        );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    CaseStatus status,
  ) async {
    await ref
        .read(caseDetailStateProvider(caseId).notifier)
        .updateCase(
          status: status,
          onCompleted: (success, error) {
            if (!context.mounted) return;
            if (!success) {
              context.showVcareToast(
                title: error ?? 'Unable to update status',
                variant: VcareToastVariant.destructive,
              );
            }
          },
        );
  }

  Future<void> _updatePriority(
    BuildContext context,
    WidgetRef ref,
    CasePriority priority,
  ) async {
    await ref
        .read(caseDetailStateProvider(caseId).notifier)
        .updateCase(
          priority: priority,
          onCompleted: (success, error) {
            if (!context.mounted) return;
            if (!success) {
              context.showVcareToast(
                title: error ?? 'Unable to update priority',
                variant: VcareToastVariant.destructive,
              );
            }
          },
        );
  }

  Future<void> _pickAssignee(BuildContext context, WidgetRef ref) async {
    final selected = await CaseAssigneePickerSheet.show(
      context,
      selectedId: caseData.assignedToId,
    );
    if (selected == null || !context.mounted) return;

    if (selected.cleared) {
      await ref
          .read(caseDetailStateProvider(caseId).notifier)
          .updateCase(
            clearAssignedTo: true,
            onCompleted: (success, error) {
              if (!context.mounted) return;
              if (!success) {
                context.showVcareToast(
                  title: error ?? 'Unable to clear assignee',
                  variant: VcareToastVariant.destructive,
                );
              }
            },
          );
      return;
    }

    final assignee = selected.assignee;
    if (assignee == null) return;

    await ref
        .read(caseDetailStateProvider(caseId).notifier)
        .updateCase(
          assignedTo: assignee.id,
          assignee: assignee,
          onCompleted: (success, error) {
            if (!context.mounted) return;
            if (!success) {
              context.showVcareToast(
                title: error ?? 'Unable to update assignee',
                variant: VcareToastVariant.destructive,
              );
            }
          },
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vcare = context.vcare;
    final daysOpen = getDaysOpen(caseData.createdAt);
    final typeLabel = resolveCaseTypeLabel(caseData.caseType);
    final shortId = formatCaseIdShort(
      caseData.id.isNotEmpty ? caseData.id : caseData.caseNumber,
    );
    final typeOptions = <String>{
      ...caseTypeOptions,
      if (typeLabel.isNotEmpty) typeLabel,
    }.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          _CaseIdChip(
            label: shortId.isEmpty ? 'ID' : shortId,
            onCopy: () => _copyCaseId(context),
          ),
          const SizedBox(width: 8),
          _HeaderDropdown(
            leading: Icon(
              LucideIcons.briefcase,
              size: 12,
              color: vcare.mutedForeground,
            ),
            label: typeLabel.isEmpty ? 'Select type' : typeLabel,
            options: [
              for (final option in typeOptions) (option, option),
            ],
            selectedKey: typeLabel,
            onSelected: (value) => _updateType(context, ref, value),
          ),
          const SizedBox(width: 8),
          _HeaderDropdown(
            label: caseData.status.label,
            options: [
              for (final option in _statusOptions)
                (option.$1.name, option.$2),
            ],
            selectedKey: caseData.status.name,
            onSelected: (key) {
              final status = CaseStatus.values.firstWhere(
                (value) => value.name == key,
              );
              _updateStatus(context, ref, status);
            },
          ),
          const SizedBox(width: 8),
          _HeaderDropdown(
            label: caseData.priority.filterLabel,
            options: [
              for (final priority in CasePriority.values)
                (priority.name, priority.filterLabel),
            ],
            selectedKey: caseData.priority.name,
            borderColor: _priorityBorderColor(context, caseData.priority),
            onSelected: (key) {
              final priority = CasePriority.values.firstWhere(
                (value) => value.name == key,
              );
              _updatePriority(context, ref, priority);
            },
          ),
          const SizedBox(width: 8),
          _AssigneeChip(
            name: caseData.assignedTo.trim().isEmpty
                ? 'Unassigned'
                : caseData.assignedTo,
            onTap: () => _pickAssignee(context, ref),
          ),
          const SizedBox(width: 8),
          _DaysOpenBadge(daysOpen: daysOpen),
        ],
      ),
    );
  }

  Color _priorityBorderColor(BuildContext context, CasePriority priority) {
    final tone = switch (priority) {
      CasePriority.urgent => VCareStatusTone.danger,
      CasePriority.high => VCareStatusTone.warning,
      CasePriority.medium => VCareStatusTone.info,
      CasePriority.low => VCareStatusTone.neutral,
    };
    return VCareStatusColors.of(context, tone).border;
  }
}

class _CaseIdChip extends StatelessWidget {
  const _CaseIdChip({required this.label, required this.onCopy});

  final String label;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      height: 28,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.fullAll,
        border: Border.all(color: vcare.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: onSurface,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onCopy,
            borderRadius: VCareRadius.fullAll,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                LucideIcons.copy,
                size: 12,
                color: vcare.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDropdown extends StatelessWidget {
  const _HeaderDropdown({
    required this.label,
    required this.options,
    required this.selectedKey,
    required this.onSelected,
    this.leading,
    this.borderColor,
  });

  final String label;
  final List<(String, String)> options;
  final String selectedKey;
  final ValueChanged<String> onSelected;
  final Widget? leading;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return PopupMenuButton<String>(
      tooltip: label,
      offset: const Offset(0, 32),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.lgAll,
        side: BorderSide(color: vcare.border),
      ),
      color: theme.colorScheme.surface,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          for (final option in options)
            PopupMenuItem<String>(
              value: option.$1,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: option.$1 == selectedKey
                        ? Icon(LucideIcons.check, size: 14, color: onSurface)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      option.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: option.$1 == selectedKey
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: option.$1 == selectedKey
                            ? onSurface
                            : vcare.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ];
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: vcare.card,
          borderRadius: VCareRadius.fullAll,
          border: Border.all(color: borderColor ?? vcare.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 12,
              color: vcare.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: vcare.card,
      borderRadius: VCareRadius.fullAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.fullAll,
        child: Container(
          height: 28,
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
          decoration: BoxDecoration(
            borderRadius: VCareRadius.fullAll,
            border: Border.all(color: vcare.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: vcare.primary.withValues(alpha: 0.12),
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: vcare.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.pencil,
                size: 11,
                color: vcare.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysOpenBadge extends StatelessWidget {
  const _DaysOpenBadge({required this.daysOpen});

  final int daysOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: VCareRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clock,
            size: 11,
            color: scheme.onPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            '${daysOpen}d open',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
