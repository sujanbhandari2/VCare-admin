import 'package:flutter_template/app/app.dart';
import 'package:flutter_template/core/config/flavor/configuration.dart';
import 'package:flutter_template/core/config/flavor/configuration_provider.dart';
import 'package:flutter_template/core/config/flavor/flavor.dart';
import 'package:flutter_template/core/services/storage/storage_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/in_memory_storage_service.dart';

class _TestConfiguration extends Configuration {
  const _TestConfiguration()
    : super(
        maxCacheAge: const Duration(days: 1),
        dioCacheForceRefreshKey: 'test_force_refresh',
        hiveBoxName: 'test_box',
        baseUrl: 'https://example.com/',
      );

  @override
  String get apiBaseUrl => apiBaseUrlV2;

  @override
  Flavor get flavor => Flavor.dev;
}

void main() {
  testWidgets('App boots with ProviderScope', (WidgetTester tester) async {
    const configuration = _TestConfiguration();
    final storageService = InMemoryStorageService();

    await tester.pumpWidget(
      ConfigurationProvider(
        configuration: configuration,
        child: ProviderScope(
          overrides: [
            flavorConfigurationProvider.overrideWithValue(configuration),
            storageServiceProvider.overrideWithValue(storageService),
          ],
          child: const MyApp(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(MyApp), findsOneWidget);
  });
}
