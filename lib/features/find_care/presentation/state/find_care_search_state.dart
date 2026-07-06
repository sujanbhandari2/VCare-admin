import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';

class FindCareSearchState {
  const FindCareSearchState({
    this.providerQuery = '',
    this.submitted = '',
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.hasMore = false,
  });

  final String providerQuery;
  final String submitted;
  final List<MedicareProviderListItem> items;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final bool hasMore;

  FindCareSearchState copyWith({
    String? providerQuery,
    String? submitted,
    List<MedicareProviderListItem>? items,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    bool? hasMore,
  }) {
    return FindCareSearchState(
      providerQuery: providerQuery ?? this.providerQuery,
      submitted: submitted ?? this.submitted,
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
