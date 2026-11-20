import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_metrics.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_tasks_preview_state_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/state/my_tasks_preview_state.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_tasks_empty_state.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_tasks_preview_card.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

import '../../../../fixtures/repositories/fake_my_task_repository.dart';

Widget _wrap({
  required MyTasksPreviewState previewState,
  List<GoRoute> extraRoutes = const [],
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(child: const MyTasksPreviewCard()),
        ),
      ),
      ...extraRoutes,
    ],
  );

  return ProviderScope(
    overrides: [myTasksPreviewStateProvider.overrideWithValue(previewState)],
    child: MaterialApp.router(
      theme: ThemeData(extensions: [VCareThemeExtension.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  group('MyTasksPreviewCard', () {
    testWidgets('shows loading message', (tester) async {
      await tester.pumpWidget(
        _wrap(
          previewState: const MyTasksPreviewState(
            operation: OperationState.loading(),
          ),
        ),
      );

      expect(find.textContaining('Loading'), findsOneWidget);
    });

    testWidgets('shows error panel on failure', (tester) async {
      await tester.pumpWidget(
        _wrap(
          previewState: const MyTasksPreviewState(
            operation: OperationState.failure('boom'),
          ),
        ),
      );

      expect(find.byType(VcareInlineErrorCard), findsOneWidget);
      expect(find.textContaining('Unable to load'), findsOneWidget);
    });

    testWidgets('shows empty state when queue is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          previewState: const MyTasksPreviewState(
            operation: OperationState.success([]),
          ),
        ),
      );

      expect(find.byType(MyTasksEmptyState), findsOneWidget);
      expect(find.text('View All'), findsNothing);
    });

    testWidgets('shows task rows, overdue badge, and View All', (tester) async {
      var navigated = false;
      await tester.pumpWidget(
        _wrap(
          previewState: MyTasksPreviewState(
            operation: OperationState.success([
              sampleMyTask(title: 'Call client'),
            ]),
            metrics: const MyTaskMetrics(open: 1, overdue: 2),
          ),
          extraRoutes: [
            GoRoute(
              path: '/home/my-tasks',
              name: 'my-tasks',
              builder: (_, _) {
                navigated = true;
                return const Scaffold(body: Text('queue'));
              },
            ),
          ],
        ),
      );

      expect(find.text('Call client'), findsOneWidget);
      expect(find.textContaining('overdue'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();
      expect(navigated, isTrue);
    });
  });
}
