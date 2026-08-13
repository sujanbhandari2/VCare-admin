import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/flavor/configuration.dart';
import 'package:vcare_admin/core/config/flavor/configuration_provider.dart';
import 'package:vcare_admin/core/config/flavor/flavor.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/tenant_branding/domain/entities/tenant_branding.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/widgets/tenant_branded_image.dart';
import 'package:vcare_admin/features/home/data/vcare_assets.dart';

import '../../helpers/in_memory_storage_service.dart';

class _TestConfiguration extends Configuration {
  const _TestConfiguration()
      : super(
          maxCacheAge: const Duration(minutes: 5),
          dioCacheForceRefreshKey: 'force_refresh',
          hiveBoxName: 'test',
          baseUrl: 'https://example.com/',
        );

  @override
  String get apiBaseUrl => apiBaseUrlV1;

  @override
  Flavor get flavor => Flavor.dev;

  @override
  String get defaultTenantSlug => 'vcare-advocacy';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tenant branding UI', () {
    late InMemoryStorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
    });

    testWidgets('hydrates cached branding into ThemeData on first frame',
        (tester) async {
      await storage.set(
        'vcare.branding.vcare-advocacy',
        '{"primaryColor":"#3B82F6","secondaryColor":"#222C55","accentColor":"#F8FAFC","fontThemeKey":"modern-tech"}',
      );
      await storage.set('vcare.branding.active_slug', 'vcare-advocacy');

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          flavorConfigurationProvider.overrideWithValue(
            const _TestConfiguration(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final branding = container.read(tenantBrandingStateProvider).branding;
      expect(branding.primaryColor, '#3B82F6');
      expect(branding.fontThemeKey, 'modern-tech');

      final theme = AppTheme.light(input: branding.themeInput);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ColoredBox(
                    key: const Key('brand-primary'),
                    color: Theme.of(context).colorScheme.primary,
                    child: Text(context.vcare.fontThemeKey),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('modern-tech'), findsOneWidget);
      final coloredBox = tester.widget<ColoredBox>(
        find.byKey(const Key('brand-primary')),
      );
      expect(
        coloredBox.color?.toARGB32(),
        theme.colorScheme.primary.toARGB32(),
      );
    });

    testWidgets('TenantBrandedImage falls back to asset when source empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TenantBrandedImage(
              source: null,
              height: 40,
              fallbackAsset: VCareAssets.logo,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    test('light-only ThemeMode is used by defaults branding', () {
      final theme = AppTheme.light(input: TenantBranding.defaults.themeInput);
      expect(theme.brightness, Brightness.light);
      expect(
        theme.colorScheme.primary.toARGB32(),
        isNot(const Color(0xff912478).toARGB32()),
      );
    });
  });
}
