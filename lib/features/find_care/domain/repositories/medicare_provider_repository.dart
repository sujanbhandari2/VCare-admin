import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_results.dart';

abstract class MedicareProviderRepository {
  Future<EitherResponseOrException<MedicareProviderLookupResult>>
  searchDirectory({
    String? firstName,
    String? lastName,
    String? providerTypeContains,
    String? state,
    required int size,
    required int offset,
  });

  Future<EitherResponseOrException<MedicareProviderByNpiResult>> fetchByNpi(
    String npi,
  );

  Future<EitherResponseOrException<MedicareProviderServicesResult>>
  fetchServices({
    required String npi,
    required int offset,
    int size = 50,
  });
}
