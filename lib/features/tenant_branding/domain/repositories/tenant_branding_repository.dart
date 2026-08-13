import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/tenant_branding/domain/entities/tenant_branding.dart';

abstract class TenantBrandingRepository {
  Future<EitherResponseOrException<TenantBranding>> fetchBranding({
    bool forceRefresh = true,
  });

  Future<EitherResponseOrException<TenantBranding>> updateBranding({
    String? logoUrl,
    String? iconUrl,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    bool clearLogo = false,
    bool clearIcon = false,
  });

  Future<EitherResponseOrException<TenantBranding>> updateFontTheme({
    required String fontThemeKey,
  });
}
