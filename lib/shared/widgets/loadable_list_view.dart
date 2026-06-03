import 'package:flutter/material.dart';

import '../models/loadable_list_item.dart';
import '../state/loadable_list_state.dart';
import '../utils/extension_functions.dart';


enum LoadableListHeaderBehavior { normal, pinned, floating }

class LoadableListView<T extends LoadableListItem> extends StatefulWidget {
  const LoadableListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    this.onLoadMore,
    this.onRefresh,
    this.controller,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.loadMoreTriggerThreshold = 240,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.headerBehavior = LoadableListHeaderBehavior.normal,
    this.headerExtent,
  }) : assert(
  headerBuilder == null ||
      headerBehavior == LoadableListHeaderBehavior.normal ||
      headerExtent != null,
  'headerExtent is required when headerBehavior is pinned or floating.',
  );

  final LoadableListState<T> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double loadMoreTriggerThreshold;

  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(
      BuildContext context,
      String? message,
      Future<void> Function()? onRetry,
      )?
  errorBuilder;
  final WidgetBuilder? loadMoreLoadingBuilder;
  final Widget Function(
      BuildContext context,
      String? message,
      Future<void> Function()? onRetry,
      )?
  loadMoreErrorBuilder;

  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? footerBuilder;

  final LoadableListHeaderBehavior headerBehavior;

  /// Required when [headerBehavior] is pinned or floating.
  final double? headerExtent;

  @override
  State<LoadableListView<T>> createState() => _LoadableListViewState<T>();
}

class _LoadableListViewState<T extends LoadableListItem>
    extends State<LoadableListView<T>> {
  late ScrollController _scrollController;
  bool _ownsController = false;
  bool _isLoadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant LoadableListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _unbindController();
      _bindController();
    }
    if (!widget.state.isLoadingMore) {
      _isLoadMoreRequested = false;
    }
  }

  void _bindController() {
    if (widget.controller != null) {
      _scrollController = widget.controller!;
      _ownsController = false;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  void _unbindController() {
    _scrollController.removeListener(_onScroll);
    if (_ownsController) {
      _scrollController.dispose();
    }
  }

  @override
  void dispose() {
    _unbindController();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final shouldLoadMore =
        widget.onLoadMore != null &&
            widget.state.hasMore &&
            widget.state.items.isNotEmpty &&
            !widget.state.isLoadingMore &&
            widget.state.loadMoreErrorMessage == null &&
            !widget.state.isInitialLoading &&
            !widget.state.isInitialError &&
            !_isLoadMoreRequested &&
            _scrollController.position.extentAfter <=
                widget.loadMoreTriggerThreshold;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      widget.onLoadMore!.call().whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[
      ..._buildHeaderSlivers(context),
      _withPadding(_buildBodySliver(context)),
      if (widget.footerBuilder != null)
        SliverToBoxAdapter(child: widget.footerBuilder!(context)),
      if (_shouldShowLoadMoreFooter)
        SliverToBoxAdapter(child: _buildLoadMoreFooter(context)),
    ];

    final scrollView = CustomScrollView(
      controller: _scrollController,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      slivers: slivers,
    );

    if (widget.onRefresh == null) {
      return scrollView;
    }

    return RefreshIndicator(onRefresh: widget.onRefresh!, child: scrollView);
  }

  Widget _buildBodySliver(BuildContext context) {
    if (widget.state.isInitialLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child:
        widget.loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.state.isInitialError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child:
        widget.errorBuilder?.call(
          context,
          widget.state.operation.errorMessage,
          widget.onRefresh,
        ) ??
            _DefaultErrorView(
              message: widget.state.operation.errorMessage,
              onRetry: widget.onRefresh,
            ),
      );
    }

    if (widget.state.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child:
        widget.emptyBuilder?.call(context) ??
            Center(child: Text(context.appLocalization.no_items_found)),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return widget.itemBuilder(context, widget.state.items[index], index);
      }, childCount: widget.state.items.length),
    );
  }

  List<Widget> _buildHeaderSlivers(BuildContext context) {
    if (widget.headerBuilder == null) {
      return const <Widget>[];
    }

    final header = widget.headerBuilder!(context);
    switch (widget.headerBehavior) {
      case LoadableListHeaderBehavior.normal:
        return <Widget>[SliverToBoxAdapter(child: header)];
      case LoadableListHeaderBehavior.pinned:
        return <Widget>[
          SliverPersistentHeader(
            pinned: true,
            delegate: _FixedExtentHeaderDelegate(
              extent: widget.headerExtent ?? 0,
              child: header,
            ),
          ),
        ];
      case LoadableListHeaderBehavior.floating:
        return <Widget>[
          SliverPersistentHeader(
            floating: true,
            delegate: _FixedExtentHeaderDelegate(
              extent: widget.headerExtent ?? 0,
              child: header,
            ),
          ),
        ];
    }
  }

  Widget _withPadding(Widget sliver) {
    if (widget.padding == null) {
      return sliver;
    }
    return SliverPadding(padding: widget.padding!, sliver: sliver);
  }

  bool get _shouldShowLoadMoreFooter {
    if (widget.onLoadMore == null) {
      return false;
    }
    return widget.state.isLoadingMore ||
        widget.state.loadMoreErrorMessage != null;
  }

  Widget _buildLoadMoreFooter(BuildContext context) {
    if (widget.state.isLoadingMore) {
      return widget.loadMoreLoadingBuilder?.call(context) ??
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
    }

    if (widget.state.loadMoreErrorMessage != null) {
      return widget.loadMoreErrorBuilder?.call(
        context,
        widget.state.loadMoreErrorMessage,
        widget.onLoadMore,
      ) ??
          _DefaultLoadMoreErrorView(
            message: widget.state.loadMoreErrorMessage,
            onRetry: widget.onLoadMore,
          );
    }

    return const SizedBox.shrink();
  }
}

class _FixedExtentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedExtentHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return SizedBox(height: extent, child: child);
  }

  @override
  bool shouldRebuild(covariant _FixedExtentHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}

class _DefaultErrorView extends StatelessWidget {
  const _DefaultErrorView({this.message, this.onRetry});

  final String? message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message ?? context.appLocalization.something_went_wrong),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: Text(context.appLocalization.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DefaultLoadMoreErrorView extends StatelessWidget {
  const _DefaultLoadMoreErrorView({this.message, this.onRetry});

  final String? message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message ?? context.appLocalization.failed_to_load_more_items,
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(context.appLocalization.retry),
            ),
        ],
      ),
    );
  }
}
