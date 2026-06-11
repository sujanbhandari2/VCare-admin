import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';

/// Compact carousel card — parity with web [HomeSavedProviderCard].
class HomeSavedProviderCard extends StatelessWidget {
  const HomeSavedProviderCard({
    super.key,
    required this.item,
    this.onTap,
    this.onRemove,
  });

  final SavedProviderItem item;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

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
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.tag.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: VCareColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.kind == HomeSavedProviderKind.mock &&
                          item.rating != null) ...[
                        Icon(
                          LucideIcons.star,
                          size: 12,
                          color: vcare.accent,
                          fill: 1,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: vcare.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(
                            fontSize: 11,
                            color: vcare.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 8,
            right: 8,
            child: SavedProviderRemoveButton(onTap: onRemove!),
          ),
      ],
    );
  }
}

/// Full list card — parity with web [SavedMockProviderCard] / [SavedMedicareProviderCard].
class SavedProviderListCard extends StatelessWidget {
  const SavedProviderListCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRemove,
    this.onCall,
  });

  final SavedProviderItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isMock = item.kind == HomeSavedProviderKind.mock;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: vcare.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: vcare.border),
          ),
          elevation: 0,
          shadowColor: VCareColors.primary.withValues(alpha: 0.08),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 56, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.tag.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: VCareColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  if (!isMock && item.providerSubtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.providerSubtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isMock && item.rating != null) ...[
                        Icon(
                          LucideIcons.star,
                          size: 14,
                          color: vcare.accent,
                          fill: 1,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: vcare.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isMock && onCall != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CallChip(onTap: onCall!),
                        const SizedBox(width: 8),
                        _NetworkChip(inNetwork: item.inNetwork),
                      ],
                    ),
                  ],
                  if (!isMock && item.medicareNpi != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'NPI ${item.medicareNpi}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: SavedProviderRemoveButton(
            onTap: onRemove,
            size: 36,
            iconSize: 18,
          ),
        ),
      ],
    );
  }
}

/// Heart remove control — web `fill-destructive` on frosted circle button.
class SavedProviderRemoveButton extends StatelessWidget {
  const SavedProviderRemoveButton({
    super.key,
    required this.onTap,
    this.size = 28,
    this.iconSize = 14,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: background.withValues(alpha: 0.8),
          shape: CircleBorder(side: BorderSide(color: vcare.border)),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                LucideIcons.heart,
                size: iconSize,
                color: VCareColors.destructive,
                fill: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallChip extends StatelessWidget {
  const _CallChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VCareColors.primary.withValues(alpha: 0.1),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.phone, size: 12, color: VCareColors.primary),
              const SizedBox(width: 4),
              Text(
                'Call',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VCareColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip({required this.inNetwork});

  final bool inNetwork;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: inNetwork
            ? VCareColors.primary.withValues(alpha: 0.1)
            : vcare.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        inNetwork ? 'In-network' : 'Out-of-network',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: inNetwork ? VCareColors.primary : vcare.mutedForeground,
        ),
      ),
    );
  }
}
