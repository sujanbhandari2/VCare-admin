import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/home/utils/care_team_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';

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
    } else if (member.photoUrl != null && member.photoUrl!.trim().isNotEmpty) {
      image = VCareCachedImage(
        imageUrl: member.photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: const SizedBox.shrink(),
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
          : !member.isOrg
              ? Text(
                  careTeamInitials(member.name),
                  style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                )
              : Icon(LucideIcons.building2, size: size * 0.4, color: fg),
    );
  }
}
