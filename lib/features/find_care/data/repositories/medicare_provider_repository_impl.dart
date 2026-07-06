import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/find_care/data/mappers/medicare_provider_mapper.dart';
import 'package:vcare_admin/features/find_care/data/models/medicare_provider_lookup_row_model.dart';
import 'package:vcare_admin/features/find_care/data/network/cms_medicare_api_client.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_results.dart';
import 'package:vcare_admin/features/find_care/domain/repositories/medicare_provider_repository.dart';
import 'package:vcare_admin/features/find_care/utils/cms_medicare_query_builder.dart';

class MedicareProviderRepositoryImpl implements MedicareProviderRepository {
  const MedicareProviderRepositoryImpl(this._client);

  final CmsMedicareApiClient _client;

  @override
  Future<EitherResponseOrException<MedicareProviderLookupResult>>
  searchDirectory({
    String? firstName,
    String? lastName,
    String? providerTypeContains,
    String? state,
    required int size,
    required int offset,
  }) {
    return safeNetworkCall(() async {
      final query = buildMedicareDirectorySearchQuery(
        firstName: firstName,
        lastName: lastName,
        providerTypeContains: providerTypeContains,
        state: state,
        size: size,
        offset: offset,
      );
      return _fetchLookupResult(query);
    });
  }

  @override
  Future<EitherResponseOrException<MedicareProviderByNpiResult>> fetchByNpi(
    String npi,
  ) {
    return safeNetworkCall(() async {
      final query = buildMedicareProviderNpiQuery(npi);
      final result = await _fetchLookupResult(query);
      return MedicareProviderByNpiResult(
        item: result.items.isEmpty ? null : result.items.first,
        headers: result.headers,
      );
    });
  }

  @override
  Future<EitherResponseOrException<MedicareProviderServicesResult>>
  fetchServices({
    required String npi,
    required int offset,
    int size = cmsProviderServicesPageSize,
  }) {
    return safeNetworkCall(() async {
      final query = buildMedicareProviderServicesQuery(npi, size, offset);
      final response = await _client.fetchDataViewer(query);
      final serviceLines = response.data
          .map(
            (row) => medicareProviderServiceLineFromRaw(
              rawRowFromArrays(response.headers, row),
            ),
          )
          .toList();

      return MedicareProviderServicesResult(
        serviceLines: serviceLines,
        headers: response.headers,
      );
    });
  }

  Future<MedicareProviderLookupResult> _fetchLookupResult(
    Map<String, String> query,
  ) async {
    final response = await _client.fetchDataViewer(query);
    final items = response.data
        .map(
          (row) => MedicareProviderLookupRowModel.fromArrays(
            response.headers,
            row,
          ).toListItem(),
        )
        .toList();

    return MedicareProviderLookupResult(
      items: items,
      headers: response.headers,
    );
  }
}
