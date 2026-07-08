import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';

void main() {
  group('NetworkFetchSession', () {
    test('starts requiring fresh network fetch on cold start', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(networkFetchSessionProvider), isTrue);
    });

    test('markSessionHydrated disables fresh fetch for list screens', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(networkFetchSessionProvider.notifier).markSessionHydrated();

      expect(container.read(networkFetchSessionProvider), isFalse);
    });
  });
}
