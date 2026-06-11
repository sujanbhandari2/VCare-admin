import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/utils/request_new_utils.dart';

class RequestNewProgress extends StatelessWidget {
  const RequestNewProgress({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(requestNewTotalSteps, (index) {
            final stepIndex = index + 1;
            final active = stepIndex == step;
            final done = stepIndex < step;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(
                  right: index < requestNewTotalSteps - 1 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: done || active ? VCareColors.primary : vcare.muted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'Step $step of $requestNewTotalSteps',
          style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
        ),
      ],
    );
  }
}
