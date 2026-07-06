import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/shared/models/loadable_list_item.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

/// Reusable pagination flow for [LoadableListState] notifiers.
mixin PaginatedListNotifierMixin<T extends LoadableListItem> {
  static const int defaultPageSize = 20;
  static const String searchExtraKey = 'search';

  LoadableListState<T> get state;
  set state(LoadableListState<T> value);

  bool get mounted;

  int get pageSize => defaultPageSize;

  int _currentPage = 0;
  int _requestGeneration = 0;

  String? get searchQuery {
    final value = state.extras?[searchExtraKey];
    return value is String ? value : null;
  }

  Future<EitherResponseOrException<PaginatedResult<T>>> fetchPage(
    PaginatedListRequest request,
  );

  PaginatedListRequest buildRequest({required int page}) {
    return PaginatedListRequest(
      page: page,
      limit: pageSize,
      search: searchQuery,
    );
  }

  Future<void> loadInitial({Map<String, dynamic>? extras}) async {
    final generation = ++_requestGeneration;

    if (mounted) {
      state = state.loading(extras: extras ?? state.extras);
    }

    final response = await fetchPage(buildRequest(page: 1));

    response.when(
      failure: (error) {
        if (!mounted || generation != _requestGeneration) {
          return;
        }
        state = state.failure(error.userMessage);
      },
      success: (result) {
        if (!mounted || generation != _requestGeneration) {
          return;
        }
        _currentPage = result.pagination.page;
        state = state.success(
          items: result.items,
          total: result.pagination.total,
        );
      },
    );
  }

  Future<void> refresh({Map<String, dynamic>? extras}) async {
    _currentPage = 0;
    await loadInitial(extras: extras);
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    final extras = <String, dynamic>{
      ...?state.extras,
      searchExtraKey: trimmed,
    };

    _currentPage = 0;
    await loadInitial(extras: extras);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.isInitialLoading ||
        state.isRefreshing) {
      return;
    }

    final generation = _requestGeneration;

    if (mounted) {
      state = state.loadingMore();
    }

    final nextPage = _currentPage + 1;
    final response = await fetchPage(buildRequest(page: nextPage));

    response.when(
      failure: (error) {
        if (!mounted || generation != _requestGeneration) {
          return;
        }
        state = state.appendFailure(error.userMessage);
      },
      success: (result) {
        if (!mounted || generation != _requestGeneration) {
          return;
        }
        _currentPage = result.pagination.page;
        state = state.appendSuccess(
          appendedItems: result.items,
          total: result.pagination.total,
        );
      },
    );
  }
}
