import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/presentation/pages/cases_screen.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_empty_state.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_list_skeleton.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_repository_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_state_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/widgets/feature_access_gate.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

import '../../../../fixtures/repositories/fake_case_repository.dart';
import '../../../../fixtures/repositories/fake_feature_access_repository.dart';

Widget _wrap({
  required FeatureAccess access,
  FakeCaseRepository? caseRepository,
}) {
  return ProviderScope(
    overrides: [
      fakeFeatureAccessRepositoryOverride(access),
      if (caseRepository != null)
        caseRepositoryProvider.overrideWithValue(caseRepository),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: [VCareThemeExtension.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CasesScreen(),
    ),
  );
}

Future<void> _loadFeatureAccess(WidgetTester tester) async {
  final element = tester.element(find.byType(CasesScreen));
  final container = ProviderScope.containerOf(element);
  await container
      .read(featureAccessStateProvider.notifier)
      .refreshFromApi();
}

void main() {
  group('Cases screen feature access', () {
    testWidgets('shows permission edge case when case management is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          access: const FeatureAccess(
            caseManagement: false,
            healthChat: true,
            membership: true,
          ),
        ),
      );
      await _loadFeatureAccess(tester);
      await tester.pumpAndSettle();

      expect(find.byType(FeatureAccessDeniedPanel), findsOneWidget);
      expect(
        find.text('You do not have permission to view cases.'),
        findsOneWidget,
      );
      expect(find.byType(CasesListSkeleton), findsNothing);
    });

    testWidgets('shows retry when settings fail to load', (tester) async {
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
            home: const CasesScreen(),
          ),
        ),
      );
      await _loadFeatureAccess(tester);
      await tester.pumpAndSettle();

      expect(find.byType(VcareErrorStatePanel), findsOneWidget);
      expect(find.text('Unable to load settings'), findsOneWidget);
    });

    testWidgets('loads cases when case management is enabled', (tester) async {
      final caseRepository = FakeCaseRepository();

      await tester.pumpWidget(
        _wrap(
          access: const FeatureAccess(
            caseManagement: true,
            healthChat: true,
            membership: true,
          ),
          caseRepository: caseRepository,
        ),
      );
      await _loadFeatureAccess(tester);
      await tester.pumpAndSettle();

      expect(find.byType(FeatureAccessDeniedPanel), findsNothing);
      expect(find.byType(CasesEmptyState), findsOneWidget);
    });
  });
}
