import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/users/data/repositories/associated_users_repository_impl.dart';
import 'package:vcare_admin/features/users/domain/repositories/associated_users_repository.dart';

part 'associated_users_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AssociatedUsersRepository associatedUsersRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return AssociatedUsersRepositoryImpl(apiClient);
}
