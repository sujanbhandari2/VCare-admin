import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';

class FindCareCategorySearchState {
  const FindCareCategorySearchState({
    this.submittedKeyword,
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.hasMore = false,
  });

  final String? submittedKeyword;
  final List<MedicareProviderListItem> items;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final bool hasMore;

  bool get hasSearched => submittedKeyword != null;

  FindCareCategorySearchState copyWith({
    String? submittedKeyword,
    List<MedicareProviderListItem>? items,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    bool? hasMore,
    bool clearSubmitted = false,
  }) {
    return FindCareCategorySearchState(
      submittedKeyword: clearSubmitted
          ? null
          : (submittedKeyword ?? this.submittedKeyword),
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
