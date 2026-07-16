import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_activity_builder.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_section_header.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_activity_status_chip.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';

class HomeRecentActivitySection extends StatelessWidget {
  const HomeRecentActivitySection({
    super.key,
    required this.items,
    this.onSeeAll,
    this.onItemTap,
  });

  final List<ActivityItem> items;
  final VoidCallback? onSeeAll;
  final void Function(ActivityItem item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'To do list',
          seeAllLabel: items.isNotEmpty ? 'See all' : null,
          onSeeAll: onSeeAll,
        ),
        if (items.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.listChecks,
            title: 'No tasks yet',
            description:
                'Action items and updates will appear here when something needs your attention.',
          )
        else
          Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ActivityCard(
                    item: item,
                    onTap: () => onItemTap?.call(item),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, this.onTap});

  final ActivityItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _ActivityRow(item: item, vcare: vcare),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.vcare});

  final ActivityItem item;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    if (item.kind == ActivityKind.transaction) {
      return _TransactionRow(item: item, vcare: vcare);
    }

    return Row(
      children: [
        if (item.kind == ActivityKind.message &&
            (item.photoUrl != null || item.photoAsset != null))
          ClipOval(
            child: item.photoUrl != null
                ? VCareCachedImage(
                    imageUrl: item.photoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: _IconTile(
                      icon: LucideIcons.user,
                      background: vcare.muted,
                      foreground: vcare.mutedForeground,
                    ),
                  )
                : Image.asset(
                    item.photoAsset!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
          )
        else
          _IconTile(
            icon: LucideIcons.inbox,
            background: vcare.muted,
            foreground: vcare.mutedForeground,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatWhen(item.when),
                    style: TextStyle(
                      fontSize: 10,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (item.kind == ActivityKind.request &&
                      item.statusLabel != null)
                    HomeActivityStatusChip(label: item.statusLabel!)
                  else if (item.kind == ActivityKind.message)
                    const HomeActivityStatusChip(label: 'Message'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
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
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item, required this.vcare});

  final ActivityItem item;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    final transaction = item.transaction!;
    final isFailed = transaction.status == 'Failed';
    final amount = NumberFormat.simpleCurrency(
      name: transaction.currency,
    ).format(transaction.amount);

    return Row(
      children: [
        _IconTile(
          icon: isFailed ? LucideIcons.alertTriangle : LucideIcons.receipt,
          background: isFailed
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
              : vcare.muted,
          foreground: isFailed
              ? Theme.of(context).colorScheme.error
              : vcare.mutedForeground,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isFailed
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  HomeActivityStatusChip(label: transaction.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFailed
                          ? item.subtitle
                          : DateFormat(
                              'MMM d, h:mm a',
                            ).format(transaction.paidAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatWhen(item.when),
                    style: TextStyle(
                      fontSize: 10,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 20, color: foreground),
    );
  }
}
