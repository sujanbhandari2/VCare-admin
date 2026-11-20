import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/my_tasks/utils/my_task_formatters.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

class MyTaskSnoozeSheet extends StatefulWidget {
  const MyTaskSnoozeSheet({super.key});

  static Future<DateTime?> show(BuildContext context) {
    return context.showBottomSheet<DateTime>(
      builder: (_) => const MyTaskSnoozeSheet(),
    );
  }

  @override
  State<MyTaskSnoozeSheet> createState() => _MyTaskSnoozeSheetState();
}

class _MyTaskSnoozeSheetState extends State<MyTaskSnoozeSheet> {
  MyTaskSnoozePreset _preset = MyTaskSnoozePreset.tomorrow;

  Future<void> _confirm() async {
    if (_preset == MyTaskSnoozePreset.custom) {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: now.add(const Duration(days: 1)),
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 2),
      );
      if (date == null || !mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 9,
          time?.minute ?? 0,
        ),
      );
      return;
    }

    final until = _preset.resolve();
    if (until != null) Navigator.pop(context, until);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.my_tasks_snooze_title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.my_tasks_snooze_subtitle,
              style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
            ),
            const SizedBox(height: 16),
            for (final preset in MyTaskSnoozePreset.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  _preset == preset
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _preset == preset
                      ? vcare.primary
                      : vcare.mutedForeground,
                  size: 20,
                ),
                title: Text(preset.localizedLabel(l10n)),
                onTap: () => setState(() => _preset = preset),
              ),
            const SizedBox(height: 12),
            AppButton.elevated(text: l10n.my_tasks_snooze, onPressed: _confirm),
          ],
        ),
      ),
    );
  }
}
