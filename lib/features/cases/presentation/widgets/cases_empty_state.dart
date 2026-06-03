import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/shell/data/shell_mock_data.dart';

/// Empty cases list — parity with vcareapp RequestsEmptyState.
class CasesEmptyState extends StatelessWidget {
  const CasesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: vcare.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: vcare.border, style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: VCareColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  LucideIcons.inbox,
                  color: VCareColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No requests yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                "Tell your advocate what you need — bills, providers, benefits, appeals — and we'll take it from here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: vcare.mutedForeground,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(LucideIcons.sparkles, size: 12, color: vcare.mutedForeground),
            const SizedBox(width: 6),
            Text(
              'TRY ONE OF THESE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: vcare.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.55,
          children: ShellMockData.quickCaseIdeas.map((idea) {
            return Material(
              color: vcare.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: vcare.border),
              ),
              child: InkWell(
                onTap: () => context.pushNamed(
                  AppRouter.requestNewName,
                  queryParameters: {'prompt': idea},
                ),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      idea,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
