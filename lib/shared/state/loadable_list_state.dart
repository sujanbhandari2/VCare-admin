import '../models/loadable_list_item.dart';
import 'operation_state.dart';

class LoadableListState<T extends LoadableListItem> {
  LoadableListState({
    OperationState<List<T>>? operation,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
  }) : operation = operation ?? OperationState<List<T>>.idle();

  final OperationState<List<T>> operation;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;

  // Just for extra data like search query
  Map<String, dynamic>? _extras;

  // Total data
  int? _total;

  Map<String, dynamic>? get extras => _extras;

  int get totalItems => _total ?? 0;

  List<T> get items => operation.data ?? <T>[];

  bool get hasMore => _total == null || items.length < totalItems;

  bool get isInitialLoading => operation.isLoading && items.isEmpty;

  bool get isRefreshing => operation.isLoading && items.isNotEmpty;

  bool get isInitialError => operation.hasError && items.isEmpty;

  bool get isEmpty =>
      !isInitialLoading &&
      !isInitialError &&
      !operation.hasError &&
      items.isEmpty;

  LoadableListState<T> loading({Map<String, dynamic>? extras}) =>
      LoadableListState<T>(
        operation: OperationState<List<T>>.loading(data: items),
        isLoadingMore: false,
        loadMoreErrorMessage: null,
      )
        .._extras = extras ?? this.extras
        .._total = _total;

  LoadableListState<T> success({required List<T> items, required int total}) =>
      LoadableListState<T>(operation: OperationState<List<T>>.success(items))
        .._extras = extras
        .._total = total;

  LoadableListState<T> failure(String? message) =>
      LoadableListState<T>(
          operation: OperationState<List<T>>.failure(message, data: items),
        )
        .._extras = extras
        .._total = totalItems;

  LoadableListState<T> loadingMore() =>
      LoadableListState<T>(operation: operation, isLoadingMore: true)
        .._extras = extras
        .._total = totalItems;

  LoadableListState<T> appendSuccess({
    required List<T> appendedItems,
    int? total,
  }) =>
      LoadableListState<T>(
          operation: OperationState<List<T>>.success(<T>[
            ...items,
            ...appendedItems,
          ]),
        )
        .._extras = extras
        .._total = total ?? totalItems;

  LoadableListState<T> appendFailure(String? message) =>
      LoadableListState<T>(operation: operation, loadMoreErrorMessage: message)
        .._extras = extras
        .._total = totalItems;
}
