import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_state_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_failed_payments_list_state_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/state/admin_dashboard_state.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_empty_states.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_failed_payment_row.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_section_card.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_failed_payment_mapper.dart';
import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_formatters.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_transaction_detail_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

class AdminDashboardFailedPaymentsCard extends ConsumerWidget {
  const AdminDashboardFailedPaymentsCard({super.key, required this.state});

  final AdminDashboardState state;

  Future<void> _openRecovery(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardFailedPaymentTodoItem item,
  ) async {
    final payerId = item.details.relatedId?.trim() ?? '';
    final transactionId = item.resource.id.trim();
    if (payerId.isEmpty || transactionId.isEmpty) return;

    final recovered = await TodoTransactionDetailSheet.show(
      context,
      item: item.toTodoItem(),
    );
    if (recovered != true || !context.mounted) return;
    await ref
        .read(adminFailedPaymentsListStateProvider.notifier)
        .sync(onlyIfLoaded: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vcare = context.vcare;
    final operation = state.failedPaymentsOperation;
    final rows = state.failedPaymentRows
        .take(adminDashboardWidgetPreviewLimit)
        .toList(growable: false);
    final failedCount = state.failedPaymentsCount;

    Widget body;
    if (operation.isLoading && rows.isEmpty) {
      body = const AdminDashboardSectionMessage(
        message: 'Loading failed payments…',
      );
    } else if (operation.hasError && rows.isEmpty) {
      body = VcareInlineErrorCard(
        title: 'Unable to load failed payments',
        message: operation.errorMessage,
        onRetry: () => ref
            .read(adminDashboardStateProvider.notifier)
            .refreshFailedPayments(),
      );
    } else if (rows.isEmpty) {
      body = const AdminDashboardFailedPaymentsEmptyState();
    } else {
      body = Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            AdminDashboardFailedPaymentRow(
              item: rows[i],
              onTap: () => _openRecovery(context, ref, rows[i]),
            ),
            if (i < rows.length - 1) const SizedBox(height: 6),
          ],
        ],
      );
    }

    return AdminDashboardSectionCard(
      title: 'Failed Payments',
      badgeLabel: failedCount > 0 ? failedCount.toString() : null,
      badgeColor: vcare.destructive,
      showViewAll: rows.isNotEmpty,
      onViewAll: () => context.pushNamed(AppRouter.adminFailedPaymentsName),
      child: body,
    );
  }
}
