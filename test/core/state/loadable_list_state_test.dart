import 'package:vcare_admin/shared/models/loadable_list_item.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

class ListItem extends LoadableListItem {
  ListItem._(this.v);

  factory ListItem.value(int v) {
    return ListItem._(v);
  }

  final int v;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListItem && runtimeType == other.runtimeType && v == other.v;

  @override
  int get hashCode => v.hashCode;
}

void main() {
  group('LoadableListState', () {
    test('initial state is empty and ready to load', () {
      final state = LoadableListState<ListItem>();

      expect(state.items, isEmpty);
      expect(state.isInitialLoading, isFalse);
      expect(state.isInitialError, isFalse);
      expect(state.hasMore, isTrue);
    });

    test('loading/success/failure helpers update operation state', () {
      final initial = LoadableListState<ListItem>();
      final loading = initial.loading();
      final success = loading.success(
        items: [ListItem.value(1), ListItem.value(2)],
        total: 2,
      );
      final failure = success.failure('failed');

      expect(loading.operation.isLoading, isTrue);
      expect(success.items, [ListItem.value(1), ListItem.value(2)]);
      expect(success.operation.isSuccess, isTrue);
      expect(failure.operation.hasError, isTrue);
      expect(failure.operation.errorMessage, 'failed');
      expect(failure.items, [ListItem.value(1), ListItem.value(2)]);
    });

    test('append helpers merge items and preserve pagination flags', () {
      final state = LoadableListState<ListItem>()
          .success(items: [ListItem.value(1), ListItem.value(2)], total: 2)
          .loadingMore()
          .appendSuccess(appendedItems: [ListItem.value(3)]);

      expect(state.items, [
        ListItem.value(1),
        ListItem.value(2),
        ListItem.value(3),
      ]);
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    });
  });
}
