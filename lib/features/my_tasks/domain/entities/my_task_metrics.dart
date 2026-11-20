/// Tab metrics returned alongside the paginated task list.
class MyTaskMetrics {
  const MyTaskMetrics({this.open = 0, this.overdue = 0, this.dueSoon = 0});

  final int open;
  final int overdue;
  final int dueSoon;

  static const MyTaskMetrics empty = MyTaskMetrics();

  MyTaskMetrics copyWith({int? open, int? overdue, int? dueSoon}) {
    return MyTaskMetrics(
      open: open ?? this.open,
      overdue: overdue ?? this.overdue,
      dueSoon: dueSoon ?? this.dueSoon,
    );
  }
}
