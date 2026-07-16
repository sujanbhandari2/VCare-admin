import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/saved_providers/data/repositories/saved_provider_repository_impl.dart';
import 'package:vcare_admin/features/saved_providers/domain/repositories/saved_provider_repository.dart';

part 'saved_provider_repository_provider.g.dart';

@Riverpod(keepAlive: true)
SavedProviderRepository savedProviderRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SavedProviderRepositoryImpl(apiClient);
}
