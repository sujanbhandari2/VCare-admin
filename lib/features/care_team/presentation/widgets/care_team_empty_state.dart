import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

class CareTeamEmptyState extends StatelessWidget {
  const CareTeamEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xxlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.vcare.primary.withValues(alpha: 0.1),
              borderRadius: VCareRadius.xlAll,
            ),
            child: Icon(
              LucideIcons.users,
              size: 24,
              color: context.vcare.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Build your care team',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your advocate, doctors, insurance and employer contacts so help is one tap away.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: vcare.mutedForeground,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.pushNamed(AppRouter.careTeamNewName),
            style: FilledButton.styleFrom(
              backgroundColor: context.vcare.primary,
              foregroundColor: context.theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Add a contact'),
          ),
        ],
      ),
    );
  }
}
