import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/admin_dashboard/utils/admin_dashboard_todo_pagination.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';

void main() {
  group('buildAdminTodoPagination', () {
    test('keeps the reported total while full pages keep arriving', () {
      final meta = buildAdminTodoPagination(
        request: const PaginatedListRequest(page: 1, limit: 20),
        rawItemCount: 20,
        keptItemCount: 14,
        loadedItemCount: 0,
        reportedTotal: 57,
      );

      expect(meta.total, 57);
      expect(meta.totalPages, 3);
      expect(meta.hasNext, isTrue);
      expect(meta.hasPrev, isFalse);
    });

    test('pins the total to loaded items on a short page', () {
      final meta = buildAdminTodoPagination(
        request: const PaginatedListRequest(page: 3, limit: 20),
        rawItemCount: 7,
        keptItemCount: 4,
        loadedItemCount: 26,
        reportedTotal: 57,
      );

      // Filtered-out items inflate the reported total, so `hasMore` would stay
      // true forever if the total were trusted here.
      expect(meta.total, 30);
      expect(meta.hasNext, isFalse);
      expect(meta.hasPrev, isTrue);
    });

    test('reports an empty list when the first page has nothing to keep', () {
      final meta = buildAdminTodoPagination(
        request: const PaginatedListRequest(page: 1, limit: 20),
        rawItemCount: 0,
        keptItemCount: 0,
        loadedItemCount: 0,
        reportedTotal: 0,
      );

      expect(meta.total, 0);
      expect(meta.totalPages, 0);
      expect(meta.hasNext, isFalse);
    });
  });
}
