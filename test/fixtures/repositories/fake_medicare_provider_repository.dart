import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_results.dart';
import 'package:vcare_admin/features/find_care/domain/repositories/medicare_provider_repository.dart';

class FakeMedicareProviderRepository implements MedicareProviderRepository {
  EitherResponseOrException<MedicareProviderLookupResult>? searchDirectoryResult;
  EitherResponseOrException<MedicareProviderByNpiResult>? fetchByNpiResult;
  EitherResponseOrException<MedicareProviderServicesResult>? fetchServicesResult;

  int searchDirectoryCallCount = 0;
  int fetchByNpiCallCount = 0;
  int fetchServicesCallCount = 0;

  @override
  Future<EitherResponseOrException<MedicareProviderLookupResult>>
  searchDirectory({
    String? firstName,
    String? lastName,
    String? providerTypeContains,
    String? state,
    required int size,
    required int offset,
  }) async {
    searchDirectoryCallCount++;
    return searchDirectoryResult ??
        Success(
          MedicareProviderLookupResult(
            items: const [],
            headers: const [],
          ),
        );
  }

  @override
  Future<EitherResponseOrException<MedicareProviderByNpiResult>> fetchByNpi(
    String npi,
  ) async {
    fetchByNpiCallCount++;
    return fetchByNpiResult ??
        Success(
          MedicareProviderByNpiResult(
            item: null,
            headers: const [],
          ),
        );
  }

  @override
  Future<EitherResponseOrException<MedicareProviderServicesResult>>
  fetchServices({
    required String npi,
    required int offset,
    int size = 50,
  }) async {
    fetchServicesCallCount++;
    return fetchServicesResult ??
        Success(
          MedicareProviderServicesResult(
            serviceLines: const [],
            headers: const [],
          ),
        );
  }
}

const sampleMedicareProviderRow = MedicareProviderLookupRow(
  npi: '1234567890',
  firstName: 'Jane',
  lastOrOrgName: 'Doe',
  providerType: 'Family Medicine',
  entityCode: 'I',
  street1: '123 Main St',
  city: 'San Francisco',
  state: 'CA',
  zip5: '94102',
);

const sampleMedicareProviderItem = MedicareProviderListItem(
  row: sampleMedicareProviderRow,
  raw: {'Rndrng_NPI': '1234567890'},
);
