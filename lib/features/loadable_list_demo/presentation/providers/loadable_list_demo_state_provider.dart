import 'dart:async';
import 'dart:math' as math;

import 'package:vcare_admin/features/loadable_list_demo/domain/models/demo_list_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/state/loadable_list_state.dart';

part 'loadable_list_demo_state_provider.g.dart';

@riverpod
class LoadableListDemoState extends _$LoadableListDemoState {
  static const int _pageSize = 20;

  final List<DemoListItem> _allItems = List<DemoListItem>.generate(
    87,
    (index) => DemoListItem.value(index + 1),
  );

  int _currentPage = 0;
  bool _failNextInitial = false;
  bool _failNextLoadMore = false;

  @override
  LoadableListState<DemoListItem> build() => LoadableListState<DemoListItem>();

  void failNextInitialLoad() {
    _failNextInitial = true;
  }

  void failNextLoadMoreRequest() {
    _failNextLoadMore = true;
  }

  Future<void> loadInitial() async {
    state = state.loading();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (_failNextInitial) {
      _failNextInitial = false;
      state = state.failure('Simulated initial load failure');
      return;
    }

    final end = math.min(_pageSize, _allItems.length);
    final items = _allItems.sublist(0, end);
    _currentPage = 1;

    state = state.success(items: items, total: _allItems.length);
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.loadingMore();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (_failNextLoadMore) {
      _failNextLoadMore = false;
      state = state.appendFailure('Simulated load-more failure');
      return;
    }

    final start = _currentPage * _pageSize;
    if (start >= _allItems.length) {
      state = state.appendSuccess(appendedItems: const []);
      return;
    }

    final end = math.min(start + _pageSize, _allItems.length);
    final nextItems = _allItems.sublist(start, end);
    _currentPage += 1;

    state = state.appendSuccess(appendedItems: nextItems);
  }
}
