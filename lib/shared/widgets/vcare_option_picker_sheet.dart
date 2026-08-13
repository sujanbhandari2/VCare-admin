import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Generic single-select bottom sheet for status / priority / type lists.
class VcareOptionPickerSheet<T> extends StatelessWidget {
  const VcareOptionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.labelOf,
    this.selected,
    this.onSelected,
  });

  final String title;
  final List<T> options;
  final String Function(T value) labelOf;
  final T? selected;
  final ValueChanged<T>? onSelected;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T value) labelOf,
    T? selected,
  }) {
    return context.showBottomSheet<T>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => VcareOptionPickerSheet<T>(
        title: title,
        options: options,
        labelOf: labelOf,
        selected: selected,
        onSelected: (value) => sheetContext.pop(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 16),
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == selected;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: VCareRadius.lgAll,
                    onTap: () => onSelected?.call(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              labelOf(option),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              LucideIcons.check,
                              size: 16,
                              color: context.vcare.primary,
                            )
                          else
                            Icon(
                              LucideIcons.circle,
                              size: 16,
                              color: vcare.mutedForeground.withValues(
                                alpha: 0.35,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
