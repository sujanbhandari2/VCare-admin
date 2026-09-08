import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// 1:1 contact profile card shown below the thread header in Live Chat.
class VcareMessengerThreadProfileCard extends StatelessWidget {
  const VcareMessengerThreadProfileCard({
    super.key,
    required this.conversation,
  });

  final MessengerConversation conversation;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final role = _roleLabel(conversation);
    final bio = _bio(conversation);
    final email = _peerEmail(conversation);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vcare.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            MessengerAvatar(
              label: conversation.avatarLabel,
              imageUrl: conversation.avatarUrl,
              size: 56,
              compact: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: VCareColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bio,
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                _CircularButton(
                  icon: LucideIcons.phone,
                  color: VCareColors.primary,
                  onTap: () => _launchPhone(context),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _CircularButton(
                    icon: LucideIcons.mail,
                    color: Colors.white,
                    iconColor: vcare.mutedForeground,
                    showBorder: true,
                    onTap: () => _launchEmail(context, email),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(MessengerConversation conversation) {
    for (final peer in conversation.peerUsers) {
      final role = peer.roleLabel.trim();
      if (role.isNotEmpty) {
        return role;
      }
    }
    return 'Care team';
  }

  String _bio(MessengerConversation conversation) {
    final subtitle = conversation.subtitle.trim();
    if (subtitle.isNotEmpty && subtitle.toLowerCase() != 'no messages yet') {
      return subtitle;
    }
    return 'Your dedicated care team member.';
  }

  String _peerEmail(MessengerConversation conversation) {
    for (final peer in conversation.peerUsers) {
      final email = peer.email.trim();
      if (email.isNotEmpty) {
        return email;
      }
    }
    return '';
  }

  Future<void> _launchPhone(BuildContext context) async {
    context.showVcareToast(
      title: 'Call ${conversation.title}',
      variant: VcareToastVariant.info,
    );
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      if (!context.mounted) {
        return;
      }
      context.showVcareToast(
        title: 'Could not open email for $email',
        variant: VcareToastVariant.destructive,
      );
    }
  }
}

class _CircularButton extends StatelessWidget {
  const _CircularButton({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    this.onTap,
    this.showBorder = false,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: showBorder ? Border.all(color: vcare.border) : null,
          boxShadow: [
            if (!showBorder)
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 16),
      ),
    );
  }
}
