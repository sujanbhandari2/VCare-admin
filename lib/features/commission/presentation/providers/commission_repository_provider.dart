import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/commission/data/repositories/commission_repository_impl.dart';
import 'package:vcare_admin/features/commission/domain/repositories/commission_repository.dart';

part 'commission_repository_provider.g.dart';

@Riverpod(keepAlive: true)
CommissionRepository commissionRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return CommissionRepositoryImpl(apiClient);
}
