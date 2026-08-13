import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_assignees_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Result of [CaseAssigneePickerSheet.show].
///
/// Distinguishes dismiss (null future) from Unassigned (`cleared: true`).
class CaseAssigneePickResult {
  const CaseAssigneePickResult.assignee(this.assignee) : cleared = false;

  const CaseAssigneePickResult.unassigned() : assignee = null, cleared = true;

  final CaseAssignee? assignee;
  final bool cleared;
}

/// Searchable assignee picker with an explicit Unassigned option.
class CaseAssigneePickerSheet extends ConsumerStatefulWidget {
  const CaseAssigneePickerSheet({
    super.key,
    this.selectedId,
    this.allowUnassigned = true,
  });

  final String? selectedId;
  final bool allowUnassigned;

  /// Returns `null` when dismissed; otherwise a [CaseAssigneePickResult].
  static Future<CaseAssigneePickResult?> show(
    BuildContext context, {
    String? selectedId,
    bool allowUnassigned = true,
  }) {
    return context.showBottomSheet<CaseAssigneePickResult>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CaseAssigneePickerSheet(
        selectedId: selectedId,
        allowUnassigned: allowUnassigned,
      ),
    );
  }

  @override
  ConsumerState<CaseAssigneePickerSheet> createState() =>
      _CaseAssigneePickerSheetState();
}

class _CaseAssigneePickerSheetState
    extends ConsumerState<CaseAssigneePickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(caseAssigneesStateProvider.notifier).search('');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(caseAssigneesStateProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final state = ref.watch(caseAssigneesStateProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final selectedId = widget.selectedId?.trim();

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Assign case',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search team members',
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: VCareRadius.lgAll,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 16),
                children: [
                  if (widget.allowUnassigned)
                    _AssigneeTile(
                      title: 'Unassigned',
                      subtitle: 'Clear current assignee',
                      selected: selectedId == null || selectedId.isEmpty,
                      leading: Icon(
                        LucideIcons.userX,
                        size: 16,
                        color: vcare.mutedForeground,
                      ),
                      onTap: () => context.pop(
                        const CaseAssigneePickResult.unassigned(),
                      ),
                    ),
                  if (state.searching && state.assignees.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.error != null && state.assignees.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: VcareInlineErrorCard(
                        message: state.error,
                        onRetry: () => ref
                            .read(caseAssigneesStateProvider.notifier)
                            .search(_searchController.text),
                      ),
                    )
                  else if (state.assignees.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: VcareEmptyStateCard(
                        icon: LucideIcons.users,
                        title: 'No assignees found',
                        description: 'Try a different search.',
                      ),
                    )
                  else
                    for (final assignee in state.assignees)
                      _AssigneeTile(
                        title: assignee.fullName,
                        subtitle: [
                          if (assignee.role.trim().isNotEmpty) assignee.role,
                          if (assignee.email.trim().isNotEmpty) assignee.email,
                        ].join(' · '),
                        selected: selectedId == assignee.id,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: context.vcare.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            assignee.initials,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.vcare.primary,
                            ),
                          ),
                        ),
                        onTap: () => context.pop(
                          CaseAssigneePickResult.assignee(assignee),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneeTile extends StatelessWidget {
  const _AssigneeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.leading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: VCareRadius.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.vcare.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(LucideIcons.check, size: 16, color: context.vcare.primary),
            ],
          ),
        ),
      ),
    );
  }
}
