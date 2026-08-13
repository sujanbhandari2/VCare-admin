import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_filter.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_item.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

class DocumentsFilters extends StatelessWidget {
  const DocumentsFilters({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final DocumentFilter value;
  final List<DocumentItem> items;
  final ValueChanged<DocumentFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final counts = documentFilterCounts(items);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in DocumentFilter.values) ...[
            _FilterChip(
              label: option.label,
              count: counts[option] ?? 0,
              selected: option == value,
              onTap: () => onChanged(option),
            ),
            if (option != DocumentFilter.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: selected ? context.vcare.primary : vcare.card,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? context.vcare.primary : vcare.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            '$label · $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? context.theme.colorScheme.onPrimary
                  : vcare.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
