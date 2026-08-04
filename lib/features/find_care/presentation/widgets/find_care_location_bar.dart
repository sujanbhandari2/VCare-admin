import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Matches vcareapp `LocationBar` — location row plus optional [actions] below.
class FindCareLocationBar extends StatelessWidget {
  const FindCareLocationBar({
    super.key,
    required this.locationController,
    this.actions,
    this.onDetectLocation,
    this.onClearCurrentLocation,
    this.isDetecting = false,
    this.isUsingCurrentLocation = false,
  });

  final TextEditingController locationController;
  final Widget? actions;
  final VoidCallback? onDetectLocation;
  final VoidCallback? onClearCurrentLocation;
  final bool isDetecting;
  final bool isUsingCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: vcare.accent.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: vcare.accent.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isUsingCurrentLocation
                      ? LucideIcons.navigation
                      : LucideIcons.mapPin,
                  size: 16,
                  color: vcare.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUsingCurrentLocation
                            ? 'Current location'
                            : 'Searching near',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: vcare.mutedForeground,
                        ),
                      ),
                      TextField(
                        controller: locationController,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'City, State',
                          hintStyle: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: isUsingCurrentLocation
                      ? vcare.accent.withValues(alpha: 0.18)
                      : vcare.muted,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: isDetecting
                        ? null
                        : (isUsingCurrentLocation
                              ? onClearCurrentLocation
                              : onDetectLocation),
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: isDetecting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: vcare.accent,
                                ),
                              )
                            : Icon(
                                isUsingCurrentLocation
                                    ? LucideIcons.x
                                    : LucideIcons.locateFixed,
                                size: 18,
                                color: isUsingCurrentLocation
                                    ? vcare.accent
                                    : null,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUsingCurrentLocation && onClearCurrentLocation != null) ...[
          const SizedBox(height: 8),
          Material(
            color: vcare.muted.withValues(alpha: 0.65),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: vcare.border),
            ),
            child: InkWell(
              onTap: onClearCurrentLocation,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: vcare.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Using current location · tap to use your city & state',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.rotateCcw,
                      size: 14,
                      color: vcare.accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (actions != null) ...[const SizedBox(height: 8), actions!],
      ],
    );
  }
}
