import 'package:vcare_admin/features/tenant_branding/domain/entities/tenant_branding.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class TenantBrandingState {
  const TenantBrandingState({
    this.branding = TenantBranding.defaults,
    this.activeSlug,
    this.fetchOperation = const OperationState<TenantBranding>.idle(),
    this.updateOperation = const OperationState<TenantBranding>.idle(),
  });

  final TenantBranding branding;
  final String? activeSlug;
  final OperationState<TenantBranding> fetchOperation;
  final OperationState<TenantBranding> updateOperation;

  bool get fetching => fetchOperation.isLoading;
  bool get updating => updateOperation.isLoading;
  bool get isBusy => fetching || updating;
  String? get error =>
      updateOperation.errorMessage ?? fetchOperation.errorMessage;

  TenantBrandingState copyWith({
    TenantBranding? branding,
    String? activeSlug,
    OperationState<TenantBranding>? fetchOperation,
    OperationState<TenantBranding>? updateOperation,
    bool clearActiveSlug = false,
  }) {
    return TenantBrandingState(
      branding: branding ?? this.branding,
      activeSlug: clearActiveSlug ? null : (activeSlug ?? this.activeSlug),
      fetchOperation: fetchOperation ?? this.fetchOperation,
      updateOperation: updateOperation ?? this.updateOperation,
    );
  }

  TenantBrandingState loadingFetch() => copyWith(
        fetchOperation: OperationState.loading(data: branding),
      );

  TenantBrandingState loadingUpdate() => copyWith(
        updateOperation: OperationState.loading(data: branding),
      );

  TenantBrandingState successFetch(TenantBranding data, {String? slug}) =>
      copyWith(
        branding: data,
        activeSlug: slug,
        fetchOperation: OperationState.success(data),
      );

  TenantBrandingState successUpdate(TenantBranding data, {String? slug}) =>
      copyWith(
        branding: data,
        activeSlug: slug,
        updateOperation: OperationState.success(data),
      );

  TenantBrandingState failureFetch(String? message) => copyWith(
        fetchOperation: OperationState.failure(message, data: branding),
      );

  TenantBrandingState failureUpdate(String? message) => copyWith(
        updateOperation: OperationState.failure(message, data: branding),
      );
}
