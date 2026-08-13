import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/features/home/presentation/pages/home_activity_screen.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_repository_provider.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_list_row.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';

import '../../../../fixtures/repositories/fake_client_repository.dart';
import '../../../../fixtures/repositories/fake_todo_repository.dart';

void main() {
  testWidgets('HomeActivityScreen loads and shows todo rows', (tester) async {
    final repository = FakeTodoRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoRepositoryProvider.overrideWith((ref) => repository)],
        child: MaterialApp(
          theme: ThemeData(extensions: [VCareThemeExtension.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeActivityScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('To do list'), findsOneWidget);
    expect(find.byType(TodoListRow), findsOneWidget);
    expect(find.text('Payment failed'), findsOneWidget);
  });

  testWidgets('HomeActivityScreen shows empty state when list is empty', (
    tester,
  ) async {
    final repository = FakeTodoRepository()
      ..fetchTodosResult = Success(
        PaginatedResult(
          items: const <TodoItem>[],
          pagination: const PaginationMeta(
            page: 1,
            limit: 20,
            total: 0,
            totalPages: 0,
            hasNext: false,
            hasPrev: false,
          ),
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoRepositoryProvider.overrideWith((ref) => repository)],
        child: MaterialApp(
          theme: ThemeData(extensions: [VCareThemeExtension.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeActivityScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('HomeActivityScreen opens recovery sheet for payment failed', (
    tester,
  ) async {
    final repository = FakeTodoRepository();
    final clients = FakeClientRepository()
      ..fetchPaymentMethodsResult = Success(const [
        ClientPaymentMethod(
          id: 'pm-1',
          type: ClientPaymentMethodType.creditDebitCard,
          label: 'Visa •• 4242',
          last4: '4242',
          isPrimary: true,
        ),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoRepositoryProvider.overrideWith((ref) => repository),
          clientRepositoryProvider.overrideWith((ref) => clients),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [VCareThemeExtension.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeActivityScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(TodoListRow));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't process this payment"), findsOneWidget);
    expect(find.text('Add card & charge'), findsOneWidget);
    expect(find.text('Retry payment'), findsOneWidget);
  });
}
