import 'package:flutter/material.dart';

/// An Search Box in a Material Design popup menu.
///
class PopupMenuListView<T> extends PopupMenuEntry<T> {
  /// Creates an listview item for a popup menu.
  ///
  const PopupMenuListView({
    super.key,
    required this.child,
    this.height = 320.0,
    this.padding,
  });

  /// Child Widget
  /// [child] -> Widget containing list view
  ///
  final Widget child;

  /// The minimum height of the search bar.
  ///
  /// Defaults to 280.0 pixels.
  @override
  final double height;

  /// The padding of the pop up menu list view.
  ///
  final EdgeInsets? padding;

  @override
  bool represents(T? value) => false;

  @override
  PopupMenuListViewState<T, PopupMenuListView<T>> createState() =>
      PopupMenuListViewState<T, PopupMenuListView<T>>();
}

/// The [State] for [PopupMenuListView] subclasses.
///
class PopupMenuListViewState<T, W extends PopupMenuListView<T>>
    extends State<W> {
  /// Init State
  ///
  @override
  void initState() {
    super.initState();
  }

  /// The menu list view item.
  ///
  @protected
  Widget? buildChild() {
    return widget.child;
  }

  /// The handler for when the user selects the list item.
  ///
  @protected
  void handleTap(T? t) {
    Navigator.pop<T>(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget item = Container(
      height: widget.height,
      alignment: AlignmentDirectional.centerStart,
      constraints: BoxConstraints(minHeight: widget.height),
      padding:
          widget.padding ??
          .symmetric(horizontal: theme.useMaterial3 ? 12.0 : 16.0),
      child: buildChild(),
    );

    return MergeSemantics(child: Semantics(container: true, child: item));
  }
}
