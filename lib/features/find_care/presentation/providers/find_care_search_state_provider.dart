import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_location_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/medicare_provider_repository_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/state/find_care_search_state.dart';
import 'package:vcare_admin/features/find_care/utils/cms_medicare_query_builder.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'find_care_search_state_provider.g.dart';

@Riverpod(keepAlive: true)
class FindCareSearchStateNotifier extends _$FindCareSearchStateNotifier {
  @override
  FindCareSearchState build() => const FindCareSearchState();

  void setProviderQuery(String query) {
    state = state.copyWith(providerQuery: query);
  }

  Future<bool> runSearch({bool loadMore = false}) async {
    final raw = (loadMore ? state.submitted : state.providerQuery).trim();
    if (raw.isEmpty) return false;

    final parsed = parseMedicareNameSearchInput(raw);
    if (parsed.firstName == null && parsed.lastName == null) return false;

    final offset = loadMore ? state.items.length : 0;
    if (!loadMore) {
      state = state.copyWith(
        loading: true,
        clearError: true,
        submitted: raw,
        items: [],
        hasMore: false,
      );
    } else {
      state = state.copyWith(loadingMore: true, clearError: true);
    }

    final location = ref.read(findCareSearchLocationProvider);
    final response = await ref
        .read(medicareProviderRepositoryProvider)
        .searchDirectory(
          firstName: parsed.firstName,
          lastName: parsed.lastName,
          state: location.state.trim().isEmpty ? null : location.state.trim(),
          size: findCareCategoryPageSize,
          offset: offset,
        );

    if (!ref.mounted) return false;

    return response.when(
      failure: (error) {
        state = state.copyWith(
          loading: false,
          loadingMore: false,
          error: error.userMessage,
          items: loadMore ? state.items : [],
          hasMore: false,
        );
        return false;
      },
      success: (result) {
        final merged = loadMore
            ? mergeMedicareProviderItems(
                existing: state.items,
                incoming: result.items,
              )
            : dedupeMedicareProviderItems(result.items);
        state = state.copyWith(
          loading: false,
          loadingMore: false,
          items: merged,
          hasMore: result.items.length == findCareCategoryPageSize,
        );
        return true;
      },
    );
  }

  void initializeFromQuery(String? query) {
    if (query == null || query.trim().isEmpty) return;
    state = state.copyWith(
      providerQuery: query.trim(),
      submitted: query.trim(),
    );
  }
}
