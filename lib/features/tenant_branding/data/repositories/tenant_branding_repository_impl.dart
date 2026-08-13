import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/tenant_branding/data/mappers/tenant_branding_mapper.dart';
import 'package:vcare_admin/features/tenant_branding/data/models/tenant_branding_model.dart';
import 'package:vcare_admin/features/tenant_branding/domain/entities/tenant_branding.dart';
import 'package:vcare_admin/features/tenant_branding/domain/repositories/tenant_branding_repository.dart';

class TenantBrandingRepositoryImpl implements TenantBrandingRepository {
  const TenantBrandingRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<TenantBranding>> fetchBranding({
    bool forceRefresh = true,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.settings,
        isAuthenticated: true,
        forceRefresh: forceRefresh,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => TenantBrandingModel.fromSettingsJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<TenantBranding>> updateBranding({
    String? logoUrl,
    String? iconUrl,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    bool clearLogo = false,
    bool clearIcon = false,
  }) {
    return safeNetworkCall(() async {
      final body = <String, dynamic>{};
      if (clearLogo || logoUrl != null) {
        body['primaryLogo'] = clearLogo ? null : logoUrl;
      }
      if (clearIcon || iconUrl != null) {
        body['iconMark'] = clearIcon ? null : iconUrl;
      }
      if (primaryColor != null) body['primaryColor'] = primaryColor;
      if (secondaryColor != null) body['secondaryColor'] = secondaryColor;
      if (accentColor != null) body['accentColor'] = accentColor;

      final response = await apiClient.patch(
        ApiEndpoints.settingsBranding,
        JsonRequestBody(body),
        isAuthenticated: true,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => TenantBrandingModel.fromSettingsJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<TenantBranding>> updateFontTheme({
    required String fontThemeKey,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.settingsTheme,
        JsonRequestBody({'fontThemeKey': fontThemeKey}),
        isAuthenticated: true,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => TenantBrandingModel.fromSettingsJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }
}
