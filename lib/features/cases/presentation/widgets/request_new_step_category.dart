import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/utils/request_new_utils.dart';
import 'package:vcare_admin/features/vcare_sync/data/vcare_catalog.dart';

class RequestNewStepCategory extends StatelessWidget {
  const RequestNewStepCategory({
    super.key,
    required this.selectedType,
    required this.suggestedType,
    required this.onTypeSelected,
  });

  final String selectedType;
  final String? suggestedType;
  final ValueChanged<String> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final suggestedLabel = suggestedType == null
        ? null
        : requestTypeLabel(suggestedType!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pick a category',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'We picked the best match for you — change it if needed.',
          style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
        ),
        if (suggestedLabel != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: vcare.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: vcare.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.sparkles, size: 16, color: vcare.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          style: TextStyle(fontWeight: FontWeight.w600),
                          text: 'Suggested: ',
                        ),
                        TextSpan(text: suggestedLabel),
                      ],
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (final requestType in VCareCatalog.requestTypes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CategoryOption(
              label: requestType.label,
              description: requestType.description,
              selected: selectedType == requestType.value,
              onTap: () => onTypeSelected(requestType.value),
            ),
          ),
      ],
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: selected ? vcare.accent.withValues(alpha: 0.1) : vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? vcare.accent.withValues(alpha: 0.6) : vcare.border,
        ),
      ),
      elevation: selected ? 0 : 0,
      shadowColor: selected ? vcare.accent.withValues(alpha: 0.3) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: vcare.accent.withValues(alpha: 0.05),
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: vcare.accent.withValues(alpha: 0.25),
                      spreadRadius: 1,
                    ),
                  ],
                )
              : null,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? vcare.accent : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: vcare.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
