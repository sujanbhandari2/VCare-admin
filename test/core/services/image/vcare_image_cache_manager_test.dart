import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/image/vcare_image_cache_manager.dart';

void main() {
  group('VCareImageCacheManager', () {
    test('clearCache is a no-op before first image load', () async {
      // Avoid constructing the manager so path_provider is not required in
      // plain unit tests. Production code creates it lazily on first use.
      await expectLater(VCareImageCacheManager.clearCache(), completes);
    });
  });
}
