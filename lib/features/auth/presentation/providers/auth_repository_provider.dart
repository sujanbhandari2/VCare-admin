import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:vcare_admin/features/auth/data/repositories/auth_repository_impl.dart';

part 'auth_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);

  return AuthRepositoryImpl(apiClient);
}
