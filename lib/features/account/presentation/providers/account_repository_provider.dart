import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/account/data/repositories/account_repository_impl.dart';
import 'package:vcare_admin/features/account/domain/repositories/account_repository.dart';

part 'account_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AccountRepositoryImpl(apiClient);
}
