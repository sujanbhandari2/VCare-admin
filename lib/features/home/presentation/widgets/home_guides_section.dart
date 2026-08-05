import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_section_header.dart';

enum _HomeGuideLinkTone { primary, accent, muted }

class _HomeGuideLink {
  const _HomeGuideLink({
    required this.href,
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
  });

  final String href;
  final String title;
  final String description;
  final IconData icon;
  final _HomeGuideLinkTone tone;
}

/// Parity with web [HomeGuidesSection] — vertical list on mobile.
const _homeGuideLinks = [
  _HomeGuideLink(
    href: 'https://vcareadvocacy.com/agents/resources',
    title: 'Resources',
    description: 'Scripts & shareables',
    icon: LucideIcons.bookOpen,
    tone: _HomeGuideLinkTone.accent,
  ),
  _HomeGuideLink(
    href: 'https://vcareadvocacy.com/how-it-works',
    title: 'How it works',
    description: 'Explain the journey',
    icon: LucideIcons.compass,
    tone: _HomeGuideLinkTone.primary,
  ),
  _HomeGuideLink(
    href: 'https://vcareadvocacy.com/faq',
    title: 'FAQs',
    description: 'Common questions',
    icon: LucideIcons.helpCircle,
    tone: _HomeGuideLinkTone.primary,
  ),
];

class HomeGuidesSection extends StatelessWidget {
  const HomeGuidesSection({super.key});

  Future<void> _openLink(String href) async {
    await launchUrlString(href, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(title: 'Guides & resources'),
        Column(
          children: [
            for (var i = 0; i < _homeGuideLinks.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _HomeGuideLinkCard(
                link: _homeGuideLinks[i],
                onTap: () => _openLink(_homeGuideLinks[i].href),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HomeGuideLinkCard extends StatelessWidget {
  const _HomeGuideLinkCard({required this.link, required this.onTap});

  final _HomeGuideLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final borderColor = switch (link.tone) {
      _HomeGuideLinkTone.primary =>
        VCareColors.primary.withValues(alpha: 0.15),
      _HomeGuideLinkTone.accent => vcare.accent.withValues(alpha: 0.15),
      _HomeGuideLinkTone.muted => vcare.border,
    };
    final iconBackground = switch (link.tone) {
      _HomeGuideLinkTone.primary =>
        VCareColors.primary.withValues(alpha: 0.1),
      _HomeGuideLinkTone.accent => vcare.accent.withValues(alpha: 0.1),
      _HomeGuideLinkTone.muted => vcare.muted,
    };
    final iconColor = switch (link.tone) {
      _HomeGuideLinkTone.primary => VCareColors.primary,
      _HomeGuideLinkTone.accent => vcare.accent,
      _HomeGuideLinkTone.muted => vcare.mutedForeground,
    };
    final openColor = switch (link.tone) {
      _HomeGuideLinkTone.primary =>
        VCareColors.primary.withValues(alpha: 0.8),
      _HomeGuideLinkTone.accent => vcare.accent.withValues(alpha: 0.8),
      _HomeGuideLinkTone.muted => vcare.mutedForeground,
    };

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(link.icon, size: 16, color: iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: vcare.mutedForeground,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: openColor,
                    ),
                  ),
                  Icon(LucideIcons.arrowUpRight, size: 10, color: openColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
