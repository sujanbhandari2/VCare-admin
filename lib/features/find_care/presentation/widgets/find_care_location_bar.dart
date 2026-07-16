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
  });

  final TextEditingController locationController;
  final Widget? actions;
  final VoidCallback? onDetectLocation;

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
                Icon(LucideIcons.mapPin, size: 16, color: vcare.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Searching near',
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
                  color: vcare.muted,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onDetectLocation,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(LucideIcons.locateFixed, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (actions != null) ...[const SizedBox(height: 8), actions!],
      ],
    );
  }
}
