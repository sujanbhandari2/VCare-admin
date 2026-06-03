import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/home/data/home_models.dart';

class CareAvatar extends StatelessWidget {
  const CareAvatar({
    super.key,
    required this.member,
    this.size = 56,
    this.borderRadius = 16,
  });

  final CareTeamMember member;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final radius = BorderRadius.circular(borderRadius);

    Widget? image;
    if (member.photoAsset != null) {
      image = Image.asset(
        member.photoAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (member.photoUrl != null) {
      image = Image.network(
        member.photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }

    if (image != null) {
      return ClipRRect(borderRadius: radius, child: image);
    }

    final isInsurance = member.role == CareTeamRole.insurance;
    final bg = isInsurance
        ? VCareColors.primary.withValues(alpha: 0.1)
        : vcare.accent.withValues(alpha: 0.1);
    final fg = isInsurance ? VCareColors.primary : vcare.accent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      alignment: Alignment.center,
      child: member.logoText != null
          ? Text(
              member.logoText!,
              style: TextStyle(
                fontSize: size * 0.25,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            )
          : Icon(LucideIcons.building2, size: size * 0.4, color: fg),
    );
  }
}
