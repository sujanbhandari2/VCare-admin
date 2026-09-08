import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/cases_list_request.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/pages/cases_screen.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_row_card.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_list_skeleton.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_state_provider.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

import '../../../../fixtures/repositories/fake_case_repository.dart';
import '../../../../fixtures/repositories/fake_feature_access_repository.dart';

ReferralCase _case(String id) {
  return ReferralCase(
    id: id,
    caseNumber: 'CASE$id',
    title: 'Care Coordination',
    status: CaseStatus.newCase,
    priority: CasePriority.medium,
    caseType: 'Care Coordination',
    clientId: 'client-$id',
    client: ReferralCaseClient(
      id: 'client-$id',
      firstName: 'Jane',
      lastName: 'Doe',
    ),
    createdAt: '2026-08-17T00:00:00.000Z',
    updatedAt: '2026-08-17T00:00:00.000Z',
  );
}

/// Answers the first page immediately, then holds every later page so the test
/// can inspect the list while a filter/search request is still in flight.
class _PendingPageCaseRepository extends FakeCaseRepository {
  Completer<void>? pending;

  @override
  Future<EitherResponseOrException<PaginatedResult<ReferralCase>>> fetchCases(
    CasesListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    await pending?.future;

    return Success(
      PaginatedResult(
        items: [_case('1'), _case('2')],
        pagination: const PaginationMeta(
          page: 1,
          limit: 20,
          total: 2,
          totalPages: 1,
          hasNext: false,
          hasPrev: false,
        ),
      ),
    );
  }
}

Widget _wrap(_PendingPageCaseRepository repository) {
  return ProviderScope(
    overrides: [
      caseRepositoryProvider.overrideWithValue(repository),
      fakeFeatureAccessRepositoryOverride(
        const FeatureAccess(
          caseManagement: true,
          healthChat: true,
          membership: true,
        ),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: [VCareThemeExtension.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CasesScreen(),
    ),
  );
}

Future<void> _enableFeatureAccess(WidgetTester tester) async {
  final element = tester.element(find.byType(CasesScreen));
  final container = ProviderScope.containerOf(element);
  await container
      .read(featureAccessStateProvider.notifier)
      .refreshFromApi();
}

void main() {
  group('Cases screen loading skeleton', () {
    testWidgets('shimmers the cards while the first page loads', (
      tester,
    ) async {
      final repository = _PendingPageCaseRepository()
        ..pending = Completer<void>();

      await tester.pumpWidget(_wrap(repository));
      await _enableFeatureAccess(tester);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(CasesListSkeleton), findsOneWidget);

      repository.pending!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CasesListSkeleton), findsNothing);
      expect(find.byType(CaseRowCard), findsNWidgets(2));
    });

    testWidgets('swaps loaded cards for shimmer while a filter applies', (
      tester,
    ) async {
      final repository = _PendingPageCaseRepository();

      await tester.pumpWidget(_wrap(repository));
      await _enableFeatureAccess(tester);
      await tester.pumpAndSettle();
      expect(find.byType(CaseRowCard), findsNWidgets(2));

      repository.pending = Completer<void>();
      await tester.tap(find.text('Status:'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(CasesListSkeleton), findsOneWidget);
      expect(find.byType(CaseRowCard), findsNothing);

      repository.pending!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CasesListSkeleton), findsNothing);
      expect(find.byType(CaseRowCard), findsNWidgets(2));
    });

    testWidgets('swaps loaded cards for shimmer while a search runs', (
      tester,
    ) async {
      final repository = _PendingPageCaseRepository();

      await tester.pumpWidget(_wrap(repository));
      await _enableFeatureAccess(tester);
      await tester.pumpAndSettle();
      expect(find.byType(CaseRowCard), findsNWidgets(2));

      repository.pending = Completer<void>();
      await tester.enterText(find.byType(TextField), 'jane');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(CasesListSkeleton), findsOneWidget);
      expect(find.byType(CaseRowCard), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CasesListSkeleton), findsOneWidget);

      repository.pending!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CasesListSkeleton), findsNothing);
      expect(find.byType(CaseRowCard), findsNWidgets(2));
    });
  });
}
