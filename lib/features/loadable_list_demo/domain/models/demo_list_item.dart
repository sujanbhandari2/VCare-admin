import '../../../../shared/models/loadable_list_item.dart';

class DemoListItem extends LoadableListItem {
  DemoListItem._(this.v);

  factory DemoListItem.value(int v) {
    return DemoListItem._(v);
  }

  final int v;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DemoListItem && runtimeType == other.runtimeType && v == other.v;

  @override
  int get hashCode => v.hashCode;
}
