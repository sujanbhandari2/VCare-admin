import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_state_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/state/admin_dashboard_state.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_stat_card.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_formatters.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_state_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/state/feature_access_state.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

class AdminDashboardStatCards extends ConsumerWidget {
  const AdminDashboardStatCards({super.key, required this.state});

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
              child: _buildFailedPaymentsCard(context, ref),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildCountCard(
                context,
                ref,
                title: 'Open tasks',
                errorTitle: 'Unable to load tasks',
                operation: state.openTasksOperation,
                count: state.openTasksCount,
                caption: 'Assigned to you',
                emptyCaption: "You're all caught up",
                icon: LucideIcons.clipboardList,
                iconTone: AdminDashboardStatCardTone.primary,
                onTap: () => context.pushNamed(AppRouter.adminTodoListName),
                onRetry: () => ref
                    .read(adminDashboardStateProvider.notifier)
                    .load(forceRefresh: true),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildCountCard(
                context,
                ref,
                title: 'Open cases',
                errorTitle: 'Unable to load cases',
                operation: state.openCasesOperation,
                count: state.openCasesCount,
                caption: 'Assigned to you',
                emptyCaption: 'No cases assigned to you',
                icon: LucideIcons.briefcase,
                iconTone: AdminDashboardStatCardTone.secondary,
                onTap: () => context.go(AppRouter.cases),
                onRetry: () => ref
                    .read(adminDashboardStateProvider.notifier)
                    .load(forceRefresh: true),
              ),
            ),
            ?_buildMembershipCard(context, ref, itemWidth, featureAccess),
            SizedBox(
              width: itemWidth,
              child: _buildCountCard(
                context,
                ref,
                title: 'Pending documents',
                errorTitle: 'Unable to load documents',
                operation: state.pendingDocumentsOperation,
                count: state.pendingDocumentsCount,
                caption: 'Uploads awaiting review',
                emptyCaption: 'No pending documents',
                icon: LucideIcons.fileText,
                iconTone: AdminDashboardStatCardTone.warning,
                onRetry: () => ref
                    .read(adminDashboardStateProvider.notifier)
                    .load(forceRefresh: true),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFailedPaymentsCard(BuildContext context, WidgetRef ref) {
    final operation = state.failedPaymentsOperation;
    if (operation.hasError && state.failedPaymentRows.isEmpty) {
      return VcareInlineErrorCard(
        title: 'Unable to load payments',
        message: operation.errorMessage,
        compact: true,
        onRetry: () => ref
            .read(adminDashboardStateProvider.notifier)
            .refreshFailedPayments(),
        retryLabel: context.appLocalization.retry,
      );
    }

    return AdminDashboardStatCard(
      title: 'Payments failed',
      value: _failedPaymentsValue(),
      caption: state.atRiskCaption,
      captionTone: _failedPaymentsCaptionTone(),
      icon: LucideIcons.alertTriangle,
      iconTone: AdminDashboardStatCardTone.danger,
      empty: _failedPaymentsEmpty(),
      emptyCaption: 'No failed payments',
      loading: operation.isLoading,
      onTap: () => context.pushNamed(AppRouter.adminFailedPaymentsName),
    );
  }

  Widget _buildCountCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String errorTitle,
    required OperationState<int> operation,
    required int count,
    required String caption,
    required String emptyCaption,
    required IconData icon,
    required AdminDashboardStatCardTone iconTone,
    required VoidCallback onRetry,
    VoidCallback? onTap,
  }) {
    if (operation.hasError) {
      return VcareInlineErrorCard(
        title: errorTitle,
        message: operation.errorMessage,
        compact: true,
        onRetry: onRetry,
        retryLabel: context.appLocalization.retry,
      );
    }

    return AdminDashboardStatCard(
      title: title,
      value: _countValue(count),
      caption: caption,
      icon: icon,
      iconTone: iconTone,
      empty: _countEmpty(operation.isLoading, count),
      emptyCaption: emptyCaption,
      loading: operation.isLoading,
      onTap: onTap,
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
          title: 'Unable to load settings',
          message: featureAccess.error,
          compact: true,
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

    final operation = state.pendingMembershipsOperation;
    if (operation.hasError) {
      return SizedBox(
        width: itemWidth,
        child: VcareInlineErrorCard(
          title: 'Unable to load memberships',
          message: operation.errorMessage,
          compact: true,
          onRetry: () => ref
              .read(adminDashboardStateProvider.notifier)
              .refreshPendingMemberships(),
          retryLabel: context.appLocalization.retry,
        ),
      );
    }

    return SizedBox(
      width: itemWidth,
      child: AdminDashboardStatCard(
        title: 'Pending memberships',
        value: _countValue(state.pendingMembershipsCount),
        caption: 'Awaiting verification',
        icon: LucideIcons.userPlus,
        iconTone: AdminDashboardStatCardTone.success,
        empty: _countEmpty(operation.isLoading, state.pendingMembershipsCount),
        emptyCaption: 'Nothing to review',
        loading: operation.isLoading,
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
    return !state.failedPaymentsOperation.isLoading &&
        !state.failedPaymentsOperation.hasError &&
        state.atRiskAmount == 0;
  }

  String _countValue(int count) {
    return NumberFormat.decimalPattern().format(count);
  }

  bool _countEmpty(bool isLoading, int count) {
    return !isLoading && count == 0;
  }
}
