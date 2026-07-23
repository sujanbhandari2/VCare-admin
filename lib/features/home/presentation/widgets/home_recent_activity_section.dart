import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/features/home/presentation/widgets/home_section_header.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_list_row.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

class HomeRecentActivitySection extends StatelessWidget {
  const HomeRecentActivitySection({
    super.key,
    required this.items,
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.onRetry,
    this.onSeeAll,
    this.onItemTap,
    this.previewLimit = 3,
  });

  final List<TodoItem> items;
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onSeeAll;
  final void Function(TodoItem item)? onItemTap;
  final int previewLimit;

  @override
  Widget build(BuildContext context) {
    final previewItems = items.take(previewLimit).toList();
    final showSeeAll = items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'To do list',
          seeAllLabel: showSeeAll ? 'See all' : null,
          onSeeAll: onSeeAll,
        ),
        if (isLoading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (isError && items.isEmpty)
          VcareErrorStatePanel(
            title: 'Unable to load tasks',
            message: errorMessage,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            actionLabel: context.appLocalization.retry,
            onAction: onRetry,
          )
        else if (previewItems.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.listChecks,
            title: 'No tasks yet',
            description:
                'Action items and updates will appear here when something needs your attention.',
          )
        else
          Column(
            children: [
              for (final item in previewItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TodoListRow(
                    item: item,
                    onTap: () => onItemTap?.call(item),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
