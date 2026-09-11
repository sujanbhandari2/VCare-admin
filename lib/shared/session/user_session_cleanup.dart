import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/config/flavor/configuration_provider.dart';
import 'package:vcare_admin/core/services/image/vcare_image_cache_manager.dart';
import 'package:vcare_admin/core/services/network/http_cache_utils.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/data/repositories/auth_secure_token_store.dart';
import 'package:vcare_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/logged_in_user_id_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/logged_in_user_profile_id_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/biometric_login/presentation/providers/biometric_login_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_assignees_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_creation_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_detail_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_files_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_other_cases_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_tasks_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/cases_list_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_cases_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_dependents_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_detail_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_documents_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_memberships_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_payment_methods_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_transactions_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/clients_list_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_history_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_sales_history_state_provider.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_summary_state_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_state_provider.dart';
import 'package:vcare_admin/features/documents/presentation/providers/document_types_state_provider.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_list_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_category_search_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/medicare_provider_detail_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/medicare_provider_lookup_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/provider_favorites_provider.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_state_provider.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_provider.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/notification_inbox_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/user_profile_state_provider.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_providers_state_provider.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_list_state_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

const _sessionStorageKeys = <String>{
  StorageKeys.loggedInUserToken,
  StorageKeys.loggedInUserRefreshToken,
  StorageKeys.loggedInUserId,
  StorageKeys.loggedInUserUuid,
  StorageKeys.loggedInUserProfileId,
  StorageKeys.loggedInUserTenantId,
  StorageKeys.loggedInUserEmail,
  StorageKeys.loggedInUserUsername,
  StorageKeys.tokenRefreshedDate,
  StorageKeys.lastSyncedFcmToken,
  StorageKeys.lastSyncedFcmUserId,
  StorageKeys.authUser,
  StorageKeys.authMenu,
  StorageKeys.authUrls,
  StorageKeys.authTenantSlug,
};

/// Best-effort server logout before clearing the access token.
Future<void> logoutSessionBestEffort({
  required StorageService storage,
  required AuthRepository authRepository,
}) async {
  final refreshToken =
      storage.get(StorageKeys.loggedInUserRefreshToken)?.toString() ?? '';
  if (refreshToken.trim().isEmpty) {
    return;
  }

  try {
    await authRepository.logoutSession(refreshToken: refreshToken);
  } catch (_) {}
}

/// Best-effort FCM deregistration before clearing the access token.
Future<void> deregisterFcmDeviceBestEffort({
  required StorageService storage,
  required String apiBaseUrl,
}) async {
  final accessToken =
      storage.get(StorageKeys.loggedInUserToken)?.toString() ?? '';
  if (accessToken.trim().isEmpty) return;

  try {
    final logoutDio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    await logoutDio.delete(ApiEndpoints.fcmDevice);
  } catch (_) {}
}

/// Clears persisted session data and HTTP response cache.
Future<void> clearUserSessionStorage({
  required StorageService storage,
  required String apiBaseUrl,
}) async {
  // TODO: Re-enable when FCM device API is available.
  // await deregisterFcmDeviceBestEffort(storage: storage, apiBaseUrl: apiBaseUrl);

  await AuthSecureTokenStore(storage: storage).clear();

  for (final key in _sessionStorageKeys) {
    if (key == StorageKeys.loggedInUserToken ||
        key == StorageKeys.loggedInUserRefreshToken) {
      continue;
    }
    await storage.remove(key);
  }

  await storage.remove(StorageKeys.localProfile);
  await clearHttpResponseCache(storage);
  await VCareImageCacheManager.clearCache();
}

/// Invalidates in-memory user-scoped Riverpod providers.
void invalidateUserScopedProviders({
  WidgetRef? ref,
  ProviderContainer? container,
}) {
  assert(ref != null || container != null);

  void invalidate(dynamic provider) {
    if (ref != null) {
      ref.invalidate(provider);
    } else {
      container!.invalidate(provider);
    }
  }

  invalidate(featureAccessStateProvider);
  invalidate(authMeStateProvider);
  invalidate(localProfileStateProvider);
  invalidate(userProfileStateProvider);
  invalidate(loggedInUserIdProvider);
  invalidate(loggedInUserProfileIdProvider);
  invalidate(agentStatsStateProvider);
  invalidate(savedProvidersStateProvider);
  invalidate(notificationInboxStateProvider);
  invalidate(clientsListStateProvider);
  invalidate(clientDetailStateProvider);
  invalidate(clientCasesStateProvider);
  invalidate(casesListStateProvider);
  invalidate(caseDetailStateProvider);
  invalidate(caseNotesStateProvider);
  invalidate(caseFilesStateProvider);
  invalidate(caseTasksStateProvider);
  invalidate(caseOtherCasesStateProvider);
  invalidate(caseAssigneesStateProvider);
  invalidate(caseCreationStateProvider);
  invalidate(clientDocumentsStateProvider);
  invalidate(clientDependentsStateProvider);
  invalidate(clientMembershipsStateProvider);
  invalidate(clientPaymentMethodsStateProvider);
  invalidate(clientTransactionsStateProvider);
  invalidate(documentsListStateProvider);
  invalidate(documentTypesStateProvider);
  invalidate(todoListStateProvider);
  invalidate(commissionHistoryStateProvider);
  invalidate(commissionSalesHistoryStateProvider);
  invalidate(commissionSummaryStateProvider);
  invalidate(findCareSearchStateProvider);
  invalidate(findCareCategorySearchStateProvider);
  invalidate(medicareProviderDetailStateProvider);
  invalidate(medicareProviderLookupStateProvider);
  invalidate(providerFavoritesProvider);
  invalidate(networkFetchSessionProvider);
  invalidate(adminAuthSessionProvider);
  invalidate(biometricLoginStateProvider);
}

/// Clears all user session data, caches, and in-memory provider state.
Future<void> clearUserSession(
  WidgetRef ref, {
  bool navigateToLogin = false,
}) async {
  final storage = ref.read(storageServiceProvider);
  final apiBaseUrl = ref.read(flavorConfigurationProvider).apiBaseUrl;
  final authRepository = ref.read(authRepositoryProvider);

  unawaited(_tearDownMessengerBestEffort(ref));
  unawaited(
    logoutSessionBestEffort(
      storage: storage,
      authRepository: authRepository,
    ),
  );

  await clearUserSessionStorage(storage: storage, apiBaseUrl: apiBaseUrl);
  await ref.read(adminAuthSessionProvider.notifier).clearSession();
  invalidateUserScopedProviders(ref: ref);
  ref.read(networkFetchSessionProvider.notifier).resetSession();
  ref.invalidate(userLoggedInStateProvider);

  if (!navigateToLogin) return;

  try {
    AppRouter.rootNavigatorKey.currentContext?.goNamed(
      AppRouter.login.toPathName,
    );
  } catch (_) {}
}

Future<void> _tearDownMessengerBestEffort(WidgetRef ref) async {
  try {
    await ref
        .read(healthMessengerSessionProvider.notifier)
        .stopSession()
        .timeout(const Duration(seconds: 3));
  } catch (_) {}
  try {
    ref.invalidate(healthMessengerSessionProvider);
  } catch (_) {}
}

/// Storage-only cleanup for contexts without a [Ref] (e.g. interceptors).
Future<void> clearUserSessionWithoutRef({
  required StorageService storage,
  required String apiBaseUrl,
  ProviderContainer? container,
}) async {
  await clearUserSessionStorage(storage: storage, apiBaseUrl: apiBaseUrl);

  if (container == null) return;

  invalidateUserScopedProviders(container: container);
  container.read(networkFetchSessionProvider.notifier).resetSession();
  container.invalidate(userLoggedInStateProvider);
}
