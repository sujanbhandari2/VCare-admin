import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/find_care/data/mappers/medicare_provider_mapper.dart';
import 'package:vcare_admin/features/find_care/data/models/medicare_provider_lookup_row_model.dart';

void main() {
  group('MedicareProviderLookupRowModelMapper', () {
    test('maps CMS headers to entity fields', () {
      final model = MedicareProviderLookupRowModel.fromArrays(
        const [
          'Rndrng_Prvdr_First_Name',
          'Rndrng_Prvdr_Last_Org_Name',
          'Rndrng_Prvdr_State_Abrvtn',
          'Rndrng_NPI',
          'Rndrng_Prvdr_City',
          'Rndrng_Prvdr_Zip5',
          'Rndrng_Prvdr_Type',
          'Rndrng_Prvdr_Ent_Cd',
          'Rndrng_Prvdr_St1',
          'Rndrng_Prvdr_St2',
        ],
        const [
          'Jane',
          'Doe',
          'CA',
          '1234567890',
          'San Francisco',
          '94102',
          'Family Medicine',
          'I',
          '123 Main St',
          'Suite 100',
        ],
      );

      final entity = model.toEntity();

      expect(entity.firstName, 'Jane');
      expect(entity.lastOrOrgName, 'Doe');
      expect(entity.npi, '1234567890');
      expect(entity.entityCode, 'I');
      expect(entity.street2, 'Suite 100');
    });

    test('maps service line raw row', () {
      final line = medicareProviderServiceLineFromRaw(const {
        'HCPCS_Cd': '99213',
        'HCPCS_Desc': 'Office visit',
        'Place_Of_Srvc': '11',
        'HCPCS_Drug_Ind': 'N',
        'Tot_Srvcs': '10',
        'Tot_Benes': '8',
        'Avg_Mdcr_Pymt_Amt': '75.50',
      });

      expect(line.hcpcsCode, '99213');
      expect(line.totalServices, '10');
      expect(line.averageMedicarePaymentAmount, '75.50');
    });
  });
}
