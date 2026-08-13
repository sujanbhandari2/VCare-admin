import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/state/admin_dashboard_state.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_stat_card.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_formatters.dart';

class AdminDashboardStatCards extends StatelessWidget {
  const AdminDashboardStatCards({
    super.key,
    required this.state,
  });

  final AdminDashboardState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.maxWidth);
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: AdminDashboardStatCard(
                title: 'Payments failed',
                value: _failedPaymentsValue(),
                caption: state.atRiskCaption,
                captionTone: _failedPaymentsCaptionTone(),
                icon: LucideIcons.alertTriangle,
                iconTone: AdminDashboardStatCardTone.danger,
                empty: _failedPaymentsEmpty(),
                emptyCaption: 'No failed payments',
                onTap: () =>
                    context.pushNamed(AppRouter.adminFailedPaymentsName),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AdminDashboardStatCard(
                title: 'Open tasks',
                value: _countValue(
                  state.openTasksOperation.isLoading,
                  state.openTasksCount,
                ),
                caption: 'Assigned to you',
                icon: LucideIcons.clipboardList,
                iconTone: AdminDashboardStatCardTone.primary,
                empty: _countEmpty(
                  state.openTasksOperation.isLoading,
                  state.openTasksCount,
                ),
                emptyCaption: "You're all caught up",
                onTap: () => context.pushNamed(AppRouter.adminTodoListName),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AdminDashboardStatCard(
                title: 'Open cases',
                value: _countValue(
                  state.openCasesOperation.isLoading,
                  state.openCasesCount,
                ),
                caption: 'Assigned to you',
                icon: LucideIcons.briefcase,
                iconTone: AdminDashboardStatCardTone.secondary,
                empty: _countEmpty(
                  state.openCasesOperation.isLoading,
                  state.openCasesCount,
                ),
                emptyCaption: 'No cases assigned to you',
                onTap: () => context.go(AppRouter.cases),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AdminDashboardStatCard(
                title: 'Pending memberships',
                value: _countValue(
                  state.pendingMembershipsOperation.isLoading,
                  state.pendingMembershipsCount,
                ),
                caption: 'Awaiting verification',
                icon: LucideIcons.userPlus,
                iconTone: AdminDashboardStatCardTone.success,
                empty: _countEmpty(
                  state.pendingMembershipsOperation.isLoading,
                  state.pendingMembershipsCount,
                ),
                emptyCaption: 'Nothing to review',
                onTap: () =>
                    context.pushNamed(AppRouter.pendingMembershipsName),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AdminDashboardStatCard(
                title: 'Pending documents',
                value: _countValue(
                  state.pendingDocumentsOperation.isLoading,
                  state.pendingDocumentsCount,
                ),
                caption: 'Uploads awaiting review',
                icon: LucideIcons.fileText,
                iconTone: AdminDashboardStatCardTone.warning,
                empty: _countEmpty(
                  state.pendingDocumentsOperation.isLoading,
                  state.pendingDocumentsCount,
                ),
                emptyCaption: 'No pending documents',
              ),
            ),
          ],
        );
      },
    );
  }

  int _columnCount(double width) {
    if (width >= 1024) return 5;
    if (width >= 768) return 3;
    return 2;
  }

  String _failedPaymentsValue() {
    if (state.failedPaymentsOperation.isLoading) return '…';
    return formatAdminDashboardMoney(
      state.atRiskAmount,
      currency: state.atRiskCurrency,
    );
  }

  AdminDashboardStatCaptionTone _failedPaymentsCaptionTone() {
    if (state.failedPaymentsOperation.isLoading) {
      return AdminDashboardStatCaptionTone.neutral;
    }
    if (state.atRiskAmount == 0) {
      return AdminDashboardStatCaptionTone.neutral;
    }
    return AdminDashboardStatCaptionTone.negative;
  }

  bool _failedPaymentsEmpty() {
    return !state.failedPaymentsOperation.isLoading && state.atRiskAmount == 0;
  }

  String _countValue(bool isLoading, int count) {
    if (isLoading) return '…';
    return NumberFormat.decimalPattern().format(count);
  }

  bool _countEmpty(bool isLoading, int count) {
    return !isLoading && count == 0;
  }
}
