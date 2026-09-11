import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_page.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/state/admin_dashboard_state.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_stat_cards.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_repository_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_state_provider.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/widgets/shimmer.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

import '../../../../fixtures/repositories/fake_feature_access_repository.dart';

Widget _wrap(
  AdminDashboardState state, {
  FeatureAccess access = const FeatureAccess(
    caseManagement: true,
    healthChat: true,
    membership: true,
  ),
}) {
  return ProviderScope(
    overrides: [fakeFeatureAccessRepositoryOverride(access)],
    child: MaterialApp(
      theme: ThemeData(extensions: [VCareThemeExtension.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: AdminDashboardStatCards(state: state),
        ),
      ),
    ),
  );
}

Future<void> _loadFeatureAccess(WidgetTester tester) async {
  final element = tester.element(find.byType(AdminDashboardStatCards));
  final container = ProviderScope.containerOf(element);
  await container
      .read(featureAccessStateProvider.notifier)
      .refreshFromApi();
}

void main() {
  group('Admin dashboard stat cards', () {
    testWidgets('shows a shimmer per card while counts load', (tester) async {
      await tester.pumpWidget(_wrap(const AdminDashboardState().loading()));
      await _loadFeatureAccess(tester);
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(Shimmer), findsNWidgets(5));
      expect(find.text('…'), findsNothing);
    });

    testWidgets('shows resolved values once loading settles', (tester) async {
      const state = AdminDashboardState(
        failedPaymentsOperation: OperationState.success(
          AdminDashboardTodoPage.empty,
        ),
        openTasksOperation: OperationState.success(4),
        openCasesOperation: OperationState.success(2),
        pendingMembershipsOperation: OperationState.success(0),
        pendingDocumentsOperation: OperationState.success(0),
      );

      await tester.pumpWidget(_wrap(state));
      await _loadFeatureAccess(tester);
      await tester.pump();

      expect(find.byType(Shimmer), findsNothing);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Pending memberships'), findsOneWidget);
    });

    testWidgets('hides membership card when membership is disabled', (
      tester,
    ) async {
      const state = AdminDashboardState(
        failedPaymentsOperation: OperationState.success(
          AdminDashboardTodoPage.empty,
        ),
        openTasksOperation: OperationState.success(0),
        openCasesOperation: OperationState.success(0),
        pendingMembershipsOperation: OperationState.success(3),
        pendingDocumentsOperation: OperationState.success(0),
      );

      await tester.pumpWidget(
        _wrap(
          state,
          access: const FeatureAccess(
            caseManagement: true,
            healthChat: true,
            membership: false,
          ),
        ),
      );
      await _loadFeatureAccess(tester);
      await tester.pumpAndSettle();

      expect(find.text('Pending memberships'), findsNothing);
      expect(find.byType(Shimmer), findsNothing);
    });

    testWidgets('shows retry card when feature access fails', (tester) async {
      const state = AdminDashboardState(
        failedPaymentsOperation: OperationState.success(
          AdminDashboardTodoPage.empty,
        ),
        openTasksOperation: OperationState.success(0),
        openCasesOperation: OperationState.success(0),
        pendingMembershipsOperation: OperationState.success(0),
        pendingDocumentsOperation: OperationState.success(0),
      );

      final repository = FakeFeatureAccessRepository(
        FeatureAccess.disabled,
      )..nextResult = Failure(
          HttpException(message: 'Settings unavailable'),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featureAccessRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [VCareThemeExtension.light]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminDashboardStatCards(state: state),
              ),
            ),
          ),
        ),
      );
      await _loadFeatureAccess(tester);
      await tester.pumpAndSettle();

      expect(find.byType(VcareInlineErrorCard), findsOneWidget);
      expect(find.text('Pending memberships'), findsNothing);
    });
  });
}
