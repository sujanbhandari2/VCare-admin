import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';

/// Avatar + identity card with call and email shortcuts. Used for the client
/// header and for affiliate agents. Actions are disabled when the matching
/// contact detail is missing.
class ClientContactCard extends StatelessWidget {
  const ClientContactCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    this.label,
    this.phone,
    this.email,
  });

  final String? label;
  final String name;
  final String subtitle;
  final String avatarUrl;
  final String? phone;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final phoneNumber = phone?.trim();
    final emailAddress = email?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: VCareColors.cardTint,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: VCareColors.cardTintBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.vcare.background,
                borderRadius: VCareRadius.xlAll,
                border: Border.all(color: vcare.border),
              ),
              child: ClipRRect(
                borderRadius: VCareRadius.xlAll,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: VCareCachedImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: ColoredBox(
                      color: vcare.muted,
                      child: Center(
                        child: Text(
                          clientInitials(name),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null && label!.trim().isNotEmpty)
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: vcare.accent,
                      ),
                    ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ClientContactCircleAction(
              icon: LucideIcons.phone,
              filled: true,
              tooltip: 'Call',
              onTap: phoneNumber == null || phoneNumber.isEmpty
                  ? null
                  : () => launchUrlString('tel:$phoneNumber'),
            ),
            const SizedBox(width: 8),
            ClientContactCircleAction(
              icon: LucideIcons.mail,
              tooltip: 'Email',
              onTap: emailAddress == null || emailAddress.isEmpty
                  ? null
                  : () => launchUrlString('mailto:$emailAddress'),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientContactCircleAction extends StatelessWidget {
  const ClientContactCircleAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isEnabled = onTap != null;

    final backgroundColor = filled
        ? (isEnabled ? context.vcare.primary : vcare.muted)
        : context.vcare.background;
    final iconColor = filled && isEnabled
        ? Colors.white
        : vcare.mutedForeground.withValues(alpha: isEnabled ? 1 : 0.35);

    final button = Material(
      color: backgroundColor,
      shape: CircleBorder(
        side: filled
            ? BorderSide.none
            : BorderSide(
                color: vcare.border.withValues(alpha: isEnabled ? 1 : 0.6),
              ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );

    if (tooltip == null || !isEnabled) return button;

    return Tooltip(message: tooltip!, child: button);
  }
}
