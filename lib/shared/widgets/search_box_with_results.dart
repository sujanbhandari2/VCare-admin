import 'package:flutter/material.dart';

import 'package:vcare_admin/shared/utils/debouncer.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

import 'package:vcare_admin/shared/widgets/search_box.dart';

class SearchBoxWithResults extends StatefulWidget {
  const SearchBoxWithResults({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.results,
    this.resultsBuilder,
    this.margin = EdgeInsets.zero,
    this.resultsPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 16.0,
    ),
    this.onSearch,
    this.onCleared,
  });

  final TextEditingController? controller;
  final String hint;
  final Widget? results;
  final Widget? Function(BuildContext context, VoidCallback hideOverlay)?
  resultsBuilder;
  final EdgeInsets margin;
  final EdgeInsets resultsPadding;
  final void Function(String?)? onSearch;
  final VoidCallback? onCleared;

  @override
  State<SearchBoxWithResults> createState() => _SearchBoxWithResultsState();
}

class _SearchBoxWithResultsState extends State<SearchBoxWithResults> {
  /// Search Box Key
  ///
  final _boxKey = GlobalKey();

  /// Search Results Overlay Entry
  ///
  OverlayEntry? _resultsEntry;

  /// Query Debounce Handler
  ///
  final _queryDebounceHandler = Debouncer();

  /// Method to execute search
  ///
  void _executeQuery(String? s) {
    _queryDebounceHandler.debounce(const Duration(milliseconds: 500), () {
      widget.onSearch?.call(s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.theme.colorScheme;

    return SearchBox(
      key: _boxKey,
      controller: widget.controller,
      hint: widget.hint,
      borderColor: scheme.outline,
      fillColor: scheme.surface,
      filled: true,
      showClearButton: true,
      onChanged: (s) {
        final show = s != null && s.trim().isNotEmpty;
        if (_resultsEntry == null) {
          if (show) _showOverlay();
        } else {
          if (!show) _hideOverlay();
        }
        _executeQuery.call(s);
      },
      onSearched: _executeQuery,
      onCleared: () {
        _hideOverlay();
        widget.onCleared?.call();
      },
      margin: widget.margin,
    );
  }

  /// Method to show vertical overlay
  ///
  void _showOverlay() {
    final overlay = Overlay.of(context);

    final position = _boxKey.position;

    _resultsEntry = OverlayEntry(
      canSizeOverlay: true,
      builder: (context) => Positioned(
        top: (position?.dy ?? 0) + widget.margin.top + 48.0,
        left: position?.dx,
        child: Container(
          height: context.height * 0.4,
          constraints: BoxConstraints(
            maxHeight: context.height * 0.4,
            maxWidth: context.width - 32.0,
            minWidth: context.width - 32.0,
          ),
          margin: .only(top: 8.0, left: 16.0, right: 16.0),
          padding: widget.resultsPadding,
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: .circular(8.0),
          ),
          // child: widget.results,
          child:
              widget.resultsBuilder?.call(context, _hideOverlay) ??
              widget.results,
        ),
      ),
    );

    if (_resultsEntry != null) overlay.insert(_resultsEntry!);
  }

  /// Method to hide the search results overlay
  ///
  void _hideOverlay() {
    _resultsEntry?.remove();
    _resultsEntry = null;
  }

  @override
  void dispose() {
    _hideOverlay();
    _resultsEntry?.dispose();
    _queryDebounceHandler.dispose();
    super.dispose();
  }
}
