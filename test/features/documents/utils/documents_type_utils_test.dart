import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/documents/data/mappers/document_type_option_mapper.dart';
import 'package:vcare_admin/features/documents/data/models/document_type_option_model.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_type_option.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_upload_constants.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/features/documents/utils/documents_w9_utils.dart';

void main() {
  group('DocumentTypeOptionModel.listFromJson', () {
    test('maps key/label pairs and skips empty entries', () {
      final models = DocumentTypeOptionModel.listFromJson({
        'W9_FORM': 'W-9 Form',
        'CONTRACT': 'Contract',
        'AGREEMENT': 'Agreement',
        'OTHER': 'Other',
        '': 'Ignored',
        'EMPTY': '  ',
      });

      expect(models, hasLength(4));
      expect(models.first.key, 'W9_FORM');
      expect(models.first.label, 'W-9 Form');
      expect(models.last.key, 'OTHER');
      expect(models.last.label, 'Other');
    });

    test('returns empty list for non-map payloads', () {
      expect(DocumentTypeOptionModel.listFromJson(null), isEmpty);
      expect(DocumentTypeOptionModel.listFromJson([]), isEmpty);
    });
  });

  group('document type helpers', () {
    const options = [
      DocumentTypeOption(key: 'W9_FORM', label: 'W-9 Form'),
      DocumentTypeOption(key: 'CONTRACT', label: 'Contract'),
      DocumentTypeOption(key: 'OTHER', label: 'Other'),
    ];

    test('filters W9 when includeW9 is false', () {
      final filtered = filterDocumentTypeOptions(options, includeW9: false);
      expect(filtered.map((o) => o.key), ['CONTRACT', 'OTHER']);
    });

    test('keeps W9 when includeW9 is true', () {
      final filtered = filterDocumentTypeOptions(options, includeW9: true);
      expect(filtered.map((o) => o.key), ['W9_FORM', 'CONTRACT', 'OTHER']);
    });

    test('defaults to OTHER label', () {
      expect(defaultDocumentTypeLabelFrom(options), 'Other');
      expect(
        defaultDocumentTypeLabelFrom(const [
          DocumentTypeOption(key: 'CONTRACT', label: 'Contract'),
        ]),
        'Contract',
      );
      expect(defaultDocumentTypeLabelFrom(const []), defaultDocumentTypeLabel);
    });

    test('mapper converts models to entities', () {
      final entities = DocumentTypeOptionModel.listFromJson({
        'OTHER': 'Other',
      }).toEntities();
      expect(entities.single.key, 'OTHER');
      expect(entities.single.label, 'Other');
    });
  });

  group('canUploadW9Document', () {
    test('hides W9 while stats are fetching', () {
      expect(
        canUploadW9Document(
          isStatsFetching: true,
          isAgencyAssociated: false,
          hasAgencyGroup: false,
        ),
        isFalse,
      );
    });

    test('hides W9 for agency-associated agents', () {
      expect(
        canUploadW9Document(
          isStatsFetching: false,
          isAgencyAssociated: true,
          hasAgencyGroup: false,
        ),
        isFalse,
      );
    });

    test('hides W9 when local profile has agency group', () {
      expect(
        canUploadW9Document(
          isStatsFetching: false,
          isAgencyAssociated: false,
          hasAgencyGroup: true,
        ),
        isFalse,
      );
    });

    test('allows W9 for independent agents', () {
      expect(
        canUploadW9Document(
          isStatsFetching: false,
          isAgencyAssociated: false,
          hasAgencyGroup: false,
        ),
        isTrue,
      );
      expect(
        canUploadW9Document(
          isStatsFetching: false,
          isAgencyAssociated: null,
          hasAgencyGroup: false,
        ),
        isTrue,
      );
    });
  });
}
