import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_providers_state_provider.dart';

class MedicareProviderResultCardWithFavorite extends ConsumerWidget {
  const MedicareProviderResultCardWithFavorite({super.key, required this.item});

  final MedicareProviderListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vcare = context.vcare;
    final row = item.row;
    final savedProvidersState = ref.watch(savedProvidersStateProvider);
    final isFavorite = savedProvidersState.isSaved(row.npi);
    final isToggling = savedProvidersState.isToggling(row.npi);
    final name = formatMedicareProviderName(row);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: vcare.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: vcare.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.pushNamed(
              AppRouter.medicareProviderDetailName,
              pathParameters: {'npi': row.npi},
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 52, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CMS · MEDICARE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: VCareColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.providerType.isNotEmpty ? row.providerType : 'Provider',
                    style: TextStyle(
                      fontSize: 14,
                      color: vcare.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: vcare.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formatMedicareProviderLocation(row),
                          style: TextStyle(
                            fontSize: 12,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NPI ${row.npi}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            onPressed: isToggling
                ? null
                : () async {
                    final saved = await ref
                        .read(savedProvidersStateProvider.notifier)
                        .toggleSave(item);
                    if (!context.mounted || saved == null) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            saved
                                ? 'Provider saved: $name'
                                : 'Provider removed: $name',
                          ),
                        ),
                      );
                  },
            tooltip: isFavorite ? 'Remove from favorites' : 'Save to favorites',
            style: IconButton.styleFrom(
              backgroundColor: vcare.card.withValues(alpha: 0.9),
              side: BorderSide(color: vcare.border),
              minimumSize: const Size(36, 36),
            ),
            icon: Icon(
              LucideIcons.heart,
              size: 18,
              color: isFavorite
                  ? VCareColors.destructive
                  : vcare.mutedForeground,
              fill: isFavorite ? 1.0 : 0.0,
            ),
          ),
        ),
      ],
    );
  }
}
