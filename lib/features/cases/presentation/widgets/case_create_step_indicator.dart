import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Step labels: Client / Note / Case Details (or a custom subset).
class CaseCreateStepIndicator extends StatelessWidget {
  const CaseCreateStepIndicator({
    super.key,
    required this.currentStep,
    this.labels = const ['Client', 'Note', 'Case Details'],
  });

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(labels.length, (index) {
            final active = index == currentStep;
            final done = index < currentStep;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(
                  right: index < labels.length - 1 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: done || active ? context.vcare.primary : vcare.muted,
                  borderRadius: VCareRadius.fullAll,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(labels.length, (index) {
            final active = index == currentStep;
            final done = index < currentStep;
            final color = done || active
                ? context.vcare.primary
                : vcare.mutedForeground;
            return Expanded(
              child: Text(
                labels[index],
                textAlign: index == 0
                    ? TextAlign.start
                    : index == labels.length - 1
                        ? TextAlign.end
                        : TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
