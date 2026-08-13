import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_pagination.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

PaginationMeta reported({
  int page = 1,
  int limit = 20,
  int total = 0,
  int totalPages = 0,
  bool hasNext = false,
  bool hasPrev = false,
}) {
  return PaginationMeta(
    page: page,
    limit: limit,
    total: total,
    totalPages: totalPages,
    hasNext: hasNext,
    hasPrev: hasPrev,
  );
}

void main() {
  group('buildPendingMembershipPagination', () {
    test('keeps paging while full pages arrive', () {
      final meta = buildPendingMembershipPagination(
        page: 1,
        limit: 20,
        rawItemCount: 20,
        keptItemCount: 20,
        loadedItemCount: 0,
        reported: reported(page: 1, total: 57, totalPages: 3, hasNext: true),
      );

      expect(meta.total, 57);
      expect(meta.hasNext, isTrue);
      expect(meta.totalPages, 3);
    });

    test('stops paging on a short page even when total is inflated', () {
      final meta = buildPendingMembershipPagination(
        page: 3,
        limit: 20,
        rawItemCount: 8,
        keptItemCount: 8,
        loadedItemCount: 40,
        reported: reported(page: 3, total: 120, totalPages: 6, hasNext: true),
      );

      expect(meta.total, 48);
      expect(meta.hasNext, isFalse);
    });

    test('reports the same total across a full page sequence', () {
      // The header renders this total, so it must not drift while paging.
      final totals = <int>[];
      var loaded = 0;

      for (final rawItemCount in [20, 20, 8]) {
        final meta = buildPendingMembershipPagination(
          page: totals.length + 1,
          limit: 20,
          rawItemCount: rawItemCount,
          keptItemCount: rawItemCount,
          loadedItemCount: loaded,
          reported: reported(total: 48, totalPages: 3, hasNext: true),
        );
        loaded += rawItemCount;
        totals.add(meta.total);
      }

      expect(totals, [48, 48, 48]);
    });

    test('a full page that reaches the reported total ends the list', () {
      final meta = buildPendingMembershipPagination(
        page: 2,
        limit: 20,
        rawItemCount: 20,
        keptItemCount: 20,
        loadedItemCount: 20,
        reported: reported(page: 2, total: 40, totalPages: 2),
      );

      expect(meta.total, 40, reason: 'the reported total is passed through');
      expect(meta.hasNext, isFalse, reason: 'every reported row is loaded');
    });

    test('empty first page reports an empty list', () {
      final meta = buildPendingMembershipPagination(
        page: 1,
        limit: 20,
        rawItemCount: 0,
        keptItemCount: 0,
        loadedItemCount: 0,
        reported: PaginationMeta.empty,
      );

      expect(meta.total, 0);
      expect(meta.totalPages, 0);
      expect(meta.hasNext, isFalse);
    });
  });
}
