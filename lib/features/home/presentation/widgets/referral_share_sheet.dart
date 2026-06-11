import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/presentation/widgets/referral_qr_code.dart';
import 'package:vcare_admin/features/home/utils/referral_actions.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

Future<void> showReferralShareSheet(
  BuildContext context, {
  required LocalProfile profile,
}) {
  return context.showBottomSheet<void>(
    isScrollControlled: true,
    builder: (sheetContext) => _ReferralShareSheet(profile: profile),
  );
}

class _ReferralShareSheet extends StatefulWidget {
  const _ReferralShareSheet({required this.profile});

  final LocalProfile profile;

  @override
  State<_ReferralShareSheet> createState() => _ReferralShareSheetState();
}

class _ReferralShareSheetState extends State<_ReferralShareSheet> {
  bool _copied = false;
  late final ReferralActions _actions;

  @override
  void initState() {
    super.initState();
    _actions = ReferralActions(widget.profile);
  }

  Future<void> _copyLink() async {
    await _actions.copyReferralLink();
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final shareText = _actions.shareText;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Share your referral',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ReferralQrCode(
                    imageUrl: _actions.qrImageUrl,
                    size: 160,
                    padding: 8,
                    borderRadius: 16,
                  ),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: vcare.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: vcare.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REFERRAL LINK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: vcare.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: vcare.muted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    _actions.referralUrl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _CopyButton(copied: _copied, onPressed: _copyLink),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SHARE VIA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: vcare.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                _ShareChannelGrid(actions: _actions, shareText: shareText),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _actions.shareReferralLink(),
                        icon: const Icon(LucideIcons.share2, size: 16),
                        label: const Text('More'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _actions.openQrImage,
                        icon: const Icon(LucideIcons.download, size: 16),
                        label: const Text('Save QR'),
                        style: FilledButton.styleFrom(
                          backgroundColor: VCareColors.primary,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.copied, required this.onPressed});

  final bool copied;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VCareColors.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                copied ? LucideIcons.check : LucideIcons.copy,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                copied ? 'Copied' : 'Copy',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareChannelGrid extends StatelessWidget {
  const _ShareChannelGrid({required this.actions, required this.shareText});

  final ReferralActions actions;
  final String shareText;

  @override
  Widget build(BuildContext context) {
    final channels = <_ShareChannel>[
      _ShareChannel(
        label: 'WhatsApp',
        icon: LucideIcons.messageCircle,
        color: const Color(0xFF25D366),
        onTap: () => actions.openShareChannel(
          url: ReferralActions.whatsAppUrl(actions.referralUrl, shareText),
        ),
      ),
      _ShareChannel(
        label: 'Facebook',
        icon: LucideIcons.facebook,
        color: const Color(0xFF1877F2),
        onTap: () => actions.openShareChannel(
          url: ReferralActions.facebookUrl(actions.referralUrl),
        ),
      ),
      _ShareChannel(
        label: 'X',
        icon: LucideIcons.twitter,
        color: Theme.of(context).colorScheme.onSurface,
        onTap: () => actions.openShareChannel(
          url: ReferralActions.twitterUrl(actions.referralUrl, shareText),
        ),
      ),
      _ShareChannel(
        label: 'LinkedIn',
        icon: LucideIcons.linkedin,
        color: const Color(0xFF0A66C2),
        onTap: () => actions.openShareChannel(
          url: ReferralActions.linkedInUrl(actions.referralUrl),
        ),
      ),
      _ShareChannel(
        label: 'Telegram',
        icon: LucideIcons.send,
        color: const Color(0xFF229ED9),
        onTap: () => actions.openShareChannel(
          url: ReferralActions.telegramUrl(actions.referralUrl, shareText),
        ),
      ),
      _ShareChannel(
        label: 'Email',
        icon: LucideIcons.mail,
        color: Theme.of(context).colorScheme.onSurface,
        onTap: () => actions.openShareChannel(
          url: ReferralActions.emailUrl(actions.referralUrl, shareText),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: channels
          .map(
            (channel) => InkWell(
              onTap: channel.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: channel.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(channel.icon, size: 20, color: channel.color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    channel.label,
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ShareChannel {
  const _ShareChannel({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
