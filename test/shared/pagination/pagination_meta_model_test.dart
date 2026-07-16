import 'package:flutter_test/flutter_test.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta_model.dart';

void main() {
  group('PaginationMetaModel', () {
    test('parses API pagination object', () {
      final model = PaginationMetaModel.fromJson({
        'page': 1,
        'limit': 20,
        'total': 42,
        'totalPages': 3,
        'hasNext': true,
        'hasPrev': false,
      });

      expect(model.page, 1);
      expect(model.limit, 20);
      expect(model.total, 42);
      expect(model.totalPages, 3);
      expect(model.hasNext, isTrue);
      expect(model.hasPrev, isFalse);

      final entity = model.toEntity();
      expect(entity.total, 42);
      expect(entity.hasNext, isTrue);
    });

    test('coerces numeric strings', () {
      final model = PaginationMetaModel.fromJson({
        'page': '2',
        'limit': '10',
        'total': '5',
        'totalPages': '1',
        'hasNext': false,
        'hasPrev': true,
      });

      expect(model.page, 2);
      expect(model.limit, 10);
      expect(model.total, 5);
    });
  });
}
