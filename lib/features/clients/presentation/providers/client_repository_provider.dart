import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/clients/data/repositories/client_repository_impl.dart';
import 'package:vcare_admin/features/clients/domain/repositories/client_repository.dart';

part 'client_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ClientRepository clientRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientRepositoryImpl(apiClient);
}
