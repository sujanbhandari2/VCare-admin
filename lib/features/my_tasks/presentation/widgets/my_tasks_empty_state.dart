import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';

class MyTasksEmptyState extends StatelessWidget {
  const MyTasksEmptyState({super.key, this.hasSearch = false});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalization;
    return VcareEmptyStateCard(
      icon: LucideIcons.checkCircle2,
      title: hasSearch
          ? l10n.my_tasks_empty_no_matches
          : l10n.my_tasks_empty_clear,
      description: hasSearch
          ? l10n.my_tasks_empty_no_matches_desc
          : l10n.my_tasks_empty_clear_desc,
    );
  }
}
