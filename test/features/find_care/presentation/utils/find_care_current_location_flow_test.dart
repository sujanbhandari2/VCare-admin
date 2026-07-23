import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/find_care/domain/entities/current_location_result.dart';
import 'package:vcare_admin/features/find_care/domain/entities/search_location.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_current_location_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_location_repository_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/utils/find_care_current_location_flow.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/widgets/location_permission_request_bottom_sheet.dart';

import '../../../../fixtures/repositories/fake_find_care_location_repository.dart';
import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runFindCareCurrentLocationFlow', () {
    late FakeFindCareLocationRepository repository;
    late InMemoryStorageService storage;

    setUp(() {
      repository = FakeFindCareLocationRepository();
      storage = InMemoryStorageService();
    });

    Future<ProviderContainer> pumpHarness(
      WidgetTester tester, {
      required Future<void> Function(BuildContext context, WidgetRef ref)
          onReady,
    }) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late ProviderContainer container;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  container = ProviderScope.containerOf(context);
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () => onReady(context, ref),
                        child: const Text('Run'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            findCareLocationRepositoryProvider.overrideWith(
              (ref) => repository,
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pump();
      return container;
    }

    testWidgets(
      'auto flow shows explanation sheet once, then skips after cancel',
      (tester) async {
        repository.hasPermissionValue = false;

        final container = await pumpHarness(
          tester,
          onReady: (context, ref) {
            return runFindCareCurrentLocationFlow(
              context,
              ref,
              userInitiated: false,
            );
          },
        );

        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();

        expect(
          find.byType(LocationPermissionRequestBottomSheet),
          findsOneWidget,
        );
        expect(
          container
              .read(findCareCurrentLocationStateProvider)
              .autoPromptCompleted,
          isTrue,
        );

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(repository.detectCallCount, 0);

        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();

        expect(
          find.byType(LocationPermissionRequestBottomSheet),
          findsNothing,
        );
        expect(repository.detectCallCount, 0);
      },
    );

    testWidgets(
      'manual flow can re-prompt after denial and detect on allow',
      (tester) async {
        repository.hasPermissionValue = false;
        repository.detectResult = const CurrentLocationSuccess(
          SearchLocation(city: 'Phoenix', state: 'AZ'),
        );

        await pumpHarness(
          tester,
          onReady: (context, ref) {
            return runFindCareCurrentLocationFlow(
              context,
              ref,
              userInitiated: true,
            );
          },
        );

        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();
        expect(
          find.byType(LocationPermissionRequestBottomSheet),
          findsOneWidget,
        );

        await tester.tap(find.text('Allow'));
        // Wait for sheet dismiss delay before detect starts.
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(repository.detectCallCount, 1);
      },
    );

    testWidgets(
      'skips explanation sheet when permission already granted',
      (tester) async {
        repository.hasPermissionValue = true;
        repository.detectResult = const CurrentLocationSuccess(
          SearchLocation(city: 'Boise', state: 'ID'),
        );

        await pumpHarness(
          tester,
          onReady: (context, ref) {
            return runFindCareCurrentLocationFlow(
              context,
              ref,
              userInitiated: false,
            );
          },
        );

        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();

        expect(
          find.byType(LocationPermissionRequestBottomSheet),
          findsNothing,
        );
        expect(repository.detectCallCount, 1);
      },
    );
  });
}
