import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/saved_providers/domain/entities/saved_provider.dart';

abstract class SavedProviderRepository {
  Future<EitherResponseOrException<List<SavedProvider>>> fetchSavedProviders({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<SavedProvider>> saveProvider({
    required MedicareProviderLookupRow row,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<bool>> deleteSavedProvider({
    required String providerId,
    CancelToken? cancelToken,
  });
}
