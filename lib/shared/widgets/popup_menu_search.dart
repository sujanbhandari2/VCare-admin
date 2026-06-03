import 'package:flutter/material.dart';
import 'package:flutter_template/shared/utils/debouncer.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

/// An Search Box in a Material Design popup menu.
///
class PopupMenuSearch<T> extends PopupMenuEntry<T> {
  /// Creates an item for a popup menu.
  ///
  /// By default, the item is [enabled].
  const PopupMenuSearch({
    super.key,
    this.hint,
    this.onQuery,
    this.enabled = true,
    this.height = kMinInteractiveDimension,
    this.padding,
    this.queryDelay = 375,
  });

  /// The hint text for the search box.
  ///
  final String? hint;

  /// Called when the menu item is tapped.
  ///
  final void Function(String?)? onQuery;

  /// Defaults to true. If this is false, then the search field will be disabled
  ///
  final bool enabled;

  /// The minimum height of the search bar.
  ///
  /// Defaults to [kMinInteractiveDimension] pixels.
  @override
  final double height;

  /// The padding of the search box
  ///
  final EdgeInsets? padding;

  /// The query delay timing in milliseconds
  /// default is 375 milliseconds
  ///
  final int queryDelay;

  @override
  bool represents(T? value) => false;

  @override
  PopupMenuSearchState<T, PopupMenuSearch<T>> createState() =>
      PopupMenuSearchState<T, PopupMenuSearch<T>>();
}

/// The [State] for [PopupMenuSearch] subclasses.
///
class PopupMenuSearchState<T, W extends PopupMenuSearch<T>> extends State<W> {
  /// The controller for the search box.
  ///
  final _controller = TextEditingController();

  /// Debounce
  ///
  final _queryScheduler = Debouncer();

  /// Method to execute query
  ///
  void _executeQuery(String? s) {
    _queryScheduler.debounce(Duration(milliseconds: widget.queryDelay), () {
      widget.onQuery?.call(s);
    });
  }

  /// The search box contents.
  ///
  @protected
  Widget? buildChild() {
    return TextFormField(
      controller: _controller,
      onChanged: _executeQuery,
      enabled: widget.enabled,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: context.textTheme.bodyLarge?.copyWith(
          color: context.theme.hintColor,
        ),
        isDense: true,
      ),
      style: context.textTheme.bodyLarge,
    );
  }

  @override
  void dispose() {
    _queryScheduler.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item = Container(
      alignment: AlignmentDirectional.centerStart,
      constraints: BoxConstraints(minHeight: widget.height),
      padding:
          widget.padding ??
          .symmetric(horizontal: theme.useMaterial3 ? 12.0 : 16.0),
      child: buildChild(),
    );

    if (!widget.enabled) {
      final bool isDark = theme.brightness == .dark;
      item = IconTheme.merge(
        data: IconThemeData(opacity: isDark ? 0.5 : 0.38),
        child: item,
      );
    }

    return MergeSemantics(
      child: Semantics(
        enabled: widget.enabled,
        container: true,
        child: ListTileTheme.merge(
          contentPadding: .zero,
          titleTextStyle: context.textTheme.bodyMedium,
          child: item,
        ),
      ),
    );
  }
}
