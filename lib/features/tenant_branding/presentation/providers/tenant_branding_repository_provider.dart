import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/tenant_branding/data/repositories/tenant_branding_repository_impl.dart';
import 'package:vcare_admin/features/tenant_branding/data/repositories/tenant_branding_session_store.dart';
import 'package:vcare_admin/features/tenant_branding/domain/repositories/tenant_branding_repository.dart';

part 'tenant_branding_repository_provider.g.dart';

@Riverpod(keepAlive: true)
TenantBrandingSessionStore tenantBrandingSessionStore(Ref ref) {
  final storage = ref.read(storageServiceProvider);
  return TenantBrandingSessionStore(storage);
}

@Riverpod(keepAlive: true)
TenantBrandingRepository tenantBrandingRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return TenantBrandingRepositoryImpl(apiClient);
}
