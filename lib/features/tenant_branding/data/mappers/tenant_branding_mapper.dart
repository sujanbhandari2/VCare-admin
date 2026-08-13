import 'package:vcare_admin/features/tenant_branding/data/models/tenant_branding_model.dart';
import 'package:vcare_admin/features/tenant_branding/domain/entities/tenant_branding.dart';

extension TenantBrandingModelMapper on TenantBrandingModel {
  TenantBranding toEntity() {
    return TenantBranding(
      logoUrl: logoUrl,
      iconUrl: iconUrl,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      accentColor: accentColor,
      fontThemeKey: fontThemeKey,
      tenantId: tenantId,
    );
  }
}
