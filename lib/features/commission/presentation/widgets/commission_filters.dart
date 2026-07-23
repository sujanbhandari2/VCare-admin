import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';

class CommissionFilters extends StatelessWidget {
  const CommissionFilters({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CommissionFilter value;
  final ValueChanged<CommissionFilter> onChanged;

  static const _options = CommissionFilter.values;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in _options) ...[
            _FilterChip(
              label: option.label,
              selected: option == value,
              vcare: vcare,
              onTap: () => onChanged(option),
            ),
            if (option != _options.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.vcare,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VCareThemeExtension vcare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? VCareColors.primary : vcare.card,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? VCareColors.primary : vcare.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? VCareColors.primaryForeground
                  : vcare.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
