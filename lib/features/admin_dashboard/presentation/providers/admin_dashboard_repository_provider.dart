import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/data/repositories/admin_dashboard_repository_impl.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/repositories/admin_dashboard_repository.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';

part 'admin_dashboard_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AdminDashboardRepository adminDashboardRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  final caseRepository = ref.watch(caseRepositoryProvider);
  return AdminDashboardRepositoryImpl(apiClient, caseRepository);
}
