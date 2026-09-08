import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/state/admin_dashboard_state.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_stat_card.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_formatters.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_state_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/state/feature_access_state.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

class AdminDashboardStatCards extends ConsumerWidget {
  const AdminDashboardStatCards({
    super.key,
    required this.state,
  });

  final AdminDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureAccess = ref.watch(featureAccessStateProvider);

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
                loading: state.failedPaymentsOperation.isLoading,
                onTap: () =>
                    context.pushNamed(AppRouter.adminFailedPaymentsName),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AdminDashboardStatCard(
                title: 'Open tasks',
                value: _countValue(state.openTasksCount),
                caption: 'Assigned to you',
                icon: LucideIcons.clipboardList,
                iconTone: AdminDashboardStatCardTone.primary,
                empty: _countEmpty(
                  state.openTasksOperation.isLoading,
                  state.openTasksCount,
                ),
                emptyCaption: "You're all caught up",
                loading: state.openTasksOperation.isLoading,
                onTap: () => context.pushNamed(AppRouter.adminTodoListName),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AdminDashboardStatCard(
                title: 'Open cases',
                value: _countValue(state.openCasesCount),
                caption: 'Assigned to you',
                icon: LucideIcons.briefcase,
                iconTone: AdminDashboardStatCardTone.secondary,
                empty: _countEmpty(
                  state.openCasesOperation.isLoading,
                  state.openCasesCount,
                ),
                emptyCaption: 'No cases assigned to you',
                loading: state.openCasesOperation.isLoading,
                onTap: () => context.go(AppRouter.cases),
              ),
            ),
            if (_buildMembershipCard(context, ref, itemWidth, featureAccess)
                case final membershipCard?)
              membershipCard,
            SizedBox(
              width: itemWidth,
              child: AdminDashboardStatCard(
                title: 'Pending documents',
                value: _countValue(state.pendingDocumentsCount),
                caption: 'Uploads awaiting review',
                icon: LucideIcons.fileText,
                iconTone: AdminDashboardStatCardTone.warning,
                empty: _countEmpty(
                  state.pendingDocumentsOperation.isLoading,
                  state.pendingDocumentsCount,
                ),
                emptyCaption: 'No pending documents',
                loading: state.pendingDocumentsOperation.isLoading,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildMembershipCard(
    BuildContext context,
    WidgetRef ref,
    double itemWidth,
    FeatureAccessState featureAccess,
  ) {
    if (featureAccess.fetching) {
      return SizedBox(
        width: itemWidth,
        child: const AdminDashboardStatCard(
          title: 'Pending memberships',
          value: '',
          caption: 'Awaiting verification',
          icon: LucideIcons.userPlus,
          iconTone: AdminDashboardStatCardTone.success,
          loading: true,
        ),
      );
    }

    if (featureAccess.hasError) {
      return SizedBox(
        width: itemWidth,
        child: VcareInlineErrorCard(
          message: featureAccess.error ?? 'Unable to load settings',
          onRetry: () => ref
              .read(featureAccessStateProvider.notifier)
              .refreshFromApi(forceRefresh: true),
          retryLabel: context.appLocalization.retry,
        ),
      );
    }

    if (!featureAccess.membershipEnabled) {
      return null;
    }

    return SizedBox(
      width: itemWidth,
      child: AdminDashboardStatCard(
        title: 'Pending memberships',
        value: _countValue(state.pendingMembershipsCount),
        caption: 'Awaiting verification',
        icon: LucideIcons.userPlus,
        iconTone: AdminDashboardStatCardTone.success,
        empty: _countEmpty(
          state.pendingMembershipsOperation.isLoading,
          state.pendingMembershipsCount,
        ),
        emptyCaption: 'Nothing to review',
        loading: state.pendingMembershipsOperation.isLoading,
        onTap: () => context.pushNamed(AppRouter.pendingMembershipsName),
      ),
    );
  }

  int _columnCount(double width) {
    if (width >= 1024) return 5;
    if (width >= 768) return 3;
    return 2;
  }

  String _failedPaymentsValue() {
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

  String _countValue(int count) {
    return NumberFormat.decimalPattern().format(count);
  }

  bool _countEmpty(bool isLoading, int count) {
    return !isLoading && count == 0;
  }
}
