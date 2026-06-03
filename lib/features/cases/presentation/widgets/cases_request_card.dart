import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/cases/utils/cases_utils.dart';
import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/home/presentation/widgets/home_activity_status_chip.dart';
import 'package:flutter_template/features/shell/data/shell_mock_data.dart';

/// Case row card — parity with vcareapp RequestsOpen/ResolvedSection.
class CasesRequestCard extends StatelessWidget {
  const CasesRequestCard({
    super.key,
    required this.request,
    this.resolved = false,
  });

  final CareRequest request;
  final bool resolved;

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
        onTap: () => context.pushNamed(
          AppRouter.requestDetailName,
          pathParameters: {'id': request.id},
        ),
        child: Opacity(
          opacity: resolved ? 0.8 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        request.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: resolved
                              ? FontWeight.w500
                              : FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: vcare.mutedForeground.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${ShellMockData.requestTypeLabel(request.type)} · ${formatCasesWhen(request.updatedAt)}',
                  style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    HomeActivityStatusChip(
                      label: casesStatusLabel(request.status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatRequestRef(request.id),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                        fontFamily: 'monospace',
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
