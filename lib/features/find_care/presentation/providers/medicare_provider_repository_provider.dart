import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/find_care/data/network/cms_medicare_api_client.dart';
import 'package:vcare_admin/features/find_care/data/repositories/medicare_provider_repository_impl.dart';
import 'package:vcare_admin/features/find_care/domain/repositories/medicare_provider_repository.dart';

part 'medicare_provider_repository_provider.g.dart';

@Riverpod(keepAlive: true)
MedicareProviderRepository medicareProviderRepository(Ref ref) {
  return MedicareProviderRepositoryImpl(CmsMedicareApiClient());
}

@Riverpod(keepAlive: true)
CmsMedicareApiClient cmsMedicareApiClient(Ref ref) {
  return CmsMedicareApiClient();
}
