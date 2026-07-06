import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_location_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/medicare_provider_repository_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/state/find_care_category_search_state.dart';
import 'package:vcare_admin/features/find_care/utils/cms_medicare_query_builder.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'find_care_category_search_state_provider.g.dart';

@Riverpod(keepAlive: true)
class FindCareCategorySearchStateNotifier
    extends _$FindCareCategorySearchStateNotifier {
  @override
  FindCareCategorySearchState build() => const FindCareCategorySearchState();

  void reset() {
    state = const FindCareCategorySearchState();
  }

  Future<bool> search({
    required String slug,
    required String keyword,
  }) async {
    final providerType = cmsProviderTypeContainsByCategory[slug];
    if (providerType == null) return false;

    state = state.copyWith(
      loading: true,
      clearError: true,
      submittedKeyword: keyword.trim(),
      items: [],
      hasMore: false,
    );

    final parsed = parseMedicareNameSearchInput(keyword);
    final location = ref.read(findCareSearchLocationProvider);

    final response = await ref.read(medicareProviderRepositoryProvider).searchDirectory(
          firstName: parsed.firstName,
          lastName: parsed.lastName,
          providerTypeContains: providerType,
          state: location.state.trim().isEmpty ? null : location.state.trim(),
          size: findCareCategoryPageSize,
          offset: 0,
        );

    if (!ref.mounted) return false;

    return response.when(
      failure: (error) {
        state = state.copyWith(
          loading: false,
          error: error.userMessage ?? 'Request failed',
        );
        return false;
      },
      success: (result) {
        state = state.copyWith(
          loading: false,
          items: dedupeMedicareProviderItems(result.items),
          hasMore: result.items.length == findCareCategoryPageSize,
        );
        return true;
      },
    );
  }

  Future<bool> loadMore({required String slug, required String keyword}) async {
    if (!state.hasMore || state.loadingMore) return false;

    final providerType = cmsProviderTypeContainsByCategory[slug];
    if (providerType == null) return false;

    state = state.copyWith(loadingMore: true, clearError: true);
    final parsed = parseMedicareNameSearchInput(keyword);
    final location = ref.read(findCareSearchLocationProvider);

    final response = await ref.read(medicareProviderRepositoryProvider).searchDirectory(
          firstName: parsed.firstName,
          lastName: parsed.lastName,
          providerTypeContains: providerType,
          state: location.state.trim().isEmpty ? null : location.state.trim(),
          size: findCareCategoryPageSize,
          offset: state.items.length,
        );

    if (!ref.mounted) return false;

    return response.when(
      failure: (error) {
        state = state.copyWith(
          loadingMore: false,
          error: error.userMessage ?? 'Request failed',
        );
        return false;
      },
      success: (result) {
        state = state.copyWith(
          loadingMore: false,
          items: mergeMedicareProviderItems(
            existing: state.items,
            incoming: result.items,
          ),
          hasMore: result.items.length == findCareCategoryPageSize,
        );
        return true;
      },
    );
  }
}
