import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_page.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/state/admin_dashboard_state.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_failed_payments_card.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_todo_card.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(extensions: [VCareThemeExtension.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  group('Admin dashboard section edge states', () {
    testWidgets('failed payments shows the shared empty card', (tester) async {
      const state = AdminDashboardState(
        failedPaymentsOperation: OperationState.success(
          AdminDashboardTodoPage.empty,
        ),
      );

      await tester.pumpWidget(
        _wrap(const AdminDashboardFailedPaymentsCard(state: state)),
      );

      expect(find.byType(VcareEmptyStateCard), findsOneWidget);
      expect(find.text('No failed payments'), findsOneWidget);
      expect(find.text('All payments are up to date right now.'), findsOneWidget);
      // Nothing to page through, so the section hides its View All link.
      expect(find.text('View All'), findsNothing);
    });

    testWidgets('todo list shows the shared empty card', (tester) async {
      const state = AdminDashboardState(
        todoTasksOperation: OperationState.success(AdminDashboardTodoPage.empty),
      );

      await tester.pumpWidget(
        _wrap(const AdminDashboardTodoCard(state: state)),
      );

      expect(find.byType(VcareEmptyStateCard), findsOneWidget);
      expect(find.text("You're all caught up!"), findsOneWidget);
      expect(find.text('View All'), findsNothing);
    });

    testWidgets('sections show a retryable error card', (tester) async {
      const state = AdminDashboardState(
        failedPaymentsOperation: OperationState.failure('Boom'),
        todoTasksOperation: OperationState.failure('Boom'),
      );

      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              AdminDashboardFailedPaymentsCard(state: state),
              AdminDashboardTodoCard(state: state),
            ],
          ),
        ),
      );

      expect(find.byType(VcareInlineErrorCard), findsNWidgets(2));
      expect(find.text('Boom'), findsNWidgets(2));
      expect(find.byType(VcareEmptyStateCard), findsNothing);
    });
  });
}
