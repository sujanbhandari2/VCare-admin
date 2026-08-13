import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';

/// Empty state for Failed Payments, shared by the dashboard card and the full
/// list screen so both read the same.
class AdminDashboardFailedPaymentsEmptyState extends StatelessWidget {
  const AdminDashboardFailedPaymentsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const VcareEmptyStateCard(
      icon: LucideIcons.creditCard,
      title: 'No failed payments',
      description: 'All payments are up to date right now.',
    );
  }
}

/// Empty state for My Todo List, shared by the dashboard card and the full list
/// screen so both read the same.
class AdminDashboardTodoEmptyState extends StatelessWidget {
  const AdminDashboardTodoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const VcareEmptyStateCard(
      icon: LucideIcons.checkCircle2,
      title: "You're all caught up!",
      description: 'No overdue or due-soon tasks right now.',
    );
  }
}
