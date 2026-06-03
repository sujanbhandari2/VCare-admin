import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/features/cases/utils/request_new_utils.dart';

class RequestNewFooter extends StatelessWidget {
  const RequestNewFooter({
    super.key,
    required this.step,
    required this.onBack,
    required this.onContinue,
    required this.onSubmit,
  });

  final int step;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isLast = step >= requestNewTotalSteps;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.paddingOf(context).bottom + 88,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.95),
      ),
      child: Row(
        children: [
          if (step > 1) ...[
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: FilledButton(
              onPressed: isLast ? onSubmit : onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: VCareColors.primary,
                foregroundColor: VCareColors.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'Submit request' : 'Continue',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.arrowRight, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
