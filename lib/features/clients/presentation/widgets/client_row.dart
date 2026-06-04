import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/clients/domain/entities/client.dart';
import 'package:flutter_template/features/clients/utils/client_utils.dart';

class ClientRow extends StatelessWidget {
  const ClientRow({
    super.key,
    required this.client,
    this.onTap,
  });

  final ClientListItem client;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CachedNetworkImage(
                    imageUrl: client.avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => ColoredBox(
                      color: vcare.muted,
                      child: Center(
                        child: Text(
                          clientInitials(client.fullName),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
                    Text(
                      client.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      client.email,
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
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: vcare.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
