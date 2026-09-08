import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/feature_access/data/repositories/feature_access_repository_impl.dart';
import 'package:vcare_admin/features/feature_access/domain/repositories/feature_access_repository.dart';

part 'feature_access_repository_provider.g.dart';

@Riverpod(keepAlive: true)
FeatureAccessRepository featureAccessRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return FeatureAccessRepositoryImpl(apiClient);
}
