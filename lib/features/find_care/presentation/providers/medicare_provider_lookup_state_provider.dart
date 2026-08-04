import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/find_care/presentation/providers/medicare_provider_repository_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/state/medicare_provider_lookup_state.dart';
import 'package:vcare_admin/features/find_care/utils/cms_medicare_query_builder.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'medicare_provider_lookup_state_provider.g.dart';

@Riverpod(keepAlive: true)
class MedicareProviderLookupStateNotifier
    extends _$MedicareProviderLookupStateNotifier {
  @override
  MedicareProviderLookupState build() => const MedicareProviderLookupState();

  void setFirstName(String value) {
    state = state.copyWith(firstName: value);
  }

  void setLastName(String value) {
    state = state.copyWith(lastName: value);
  }

  void setStateCode(String value) {
    state = state.copyWith(state: value);
  }

  Future<bool> submitSearch() async {
    final first = state.firstName.trim();
    final last = state.lastName.trim();
    if (first.isEmpty || last.isEmpty) return false;

    final submitted = MedicareLookupSubmitted(
      firstName: first,
      lastName: last,
      state: state.state == '__any__' ? '' : state.state,
    );

    state = state.copyWith(
      submitted: submitted,
      loading: true,
      clearError: true,
      items: [],
      hasMore: false,
    );

    return _fetchPage(loadMore: false);
  }

  Future<bool> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.submitted == null) {
      return false;
    }
    state = state.copyWith(loadingMore: true, clearError: true);
    return _fetchPage(loadMore: true);
  }

  Future<bool> _fetchPage({required bool loadMore}) async {
    final criteria = state.submitted!;
    final response = await ref
        .read(medicareProviderRepositoryProvider)
        .searchDirectory(
          firstName: criteria.firstName,
          lastName: criteria.lastName,
          state: criteria.state.trim().isEmpty ? null : criteria.state.trim(),
          size: medicareLookupPageSize,
          offset: loadMore ? state.items.length : 0,
        );

    if (!ref.mounted) return false;

    return response.when(
      failure: (error) {
        state = state.copyWith(
          loading: false,
          loadingMore: false,
          error: error.userMessage ?? 'Request failed',
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
          hasMore: result.items.length == medicareLookupPageSize,
        );
        return true;
      },
    );
  }
}
