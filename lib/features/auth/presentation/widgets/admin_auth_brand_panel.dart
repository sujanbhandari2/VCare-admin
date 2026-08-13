import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/features/home/data/vcare_assets.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/widgets/tenant_branded_image.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

class AdminAuthBrandPanel extends ConsumerWidget {
  const AdminAuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(tenantBrandingStateProvider).branding;

    return Container(
      color: context.theme.colorScheme.primary,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TenantBrandedImage(
            source: branding.logoUrl,
            height: 40,
            fallbackAsset: VCareAssets.logo,
          ),
          const Spacer(),
          Text(
            'VCare Advocacy',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your personalized healthcare advocacy — guiding families through '
            'care decisions with clarity, compassion, and trusted expertise.',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.theme.colorScheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          _ContactRow(
            icon: LucideIcons.phone,
            label: '(866) 484-8239',
            color: context.theme.colorScheme.onPrimary,
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: LucideIcons.mail,
            label: 'vcare@vitafyhealth.com',
            color: context.theme.colorScheme.onPrimary,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.9)),
        const SizedBox(width: 10),
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
