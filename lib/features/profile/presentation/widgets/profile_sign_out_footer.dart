import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';

class ProfileSignOutFooter extends StatelessWidget {
  const ProfileSignOutFooter({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      children: [
        Material(
          color: vcare.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: vcare.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSignOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.logOut,
                    size: 16,
                    color: VCareColors.destructive,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign out',
                    style: TextStyle(
                      color: VCareColors.destructive,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'VCare v1.0 · Mock data',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
        ),
      ],
    );
  }
}
