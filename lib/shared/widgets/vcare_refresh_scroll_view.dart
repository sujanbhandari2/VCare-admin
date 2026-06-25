import 'package:flutter/material.dart';

/// Pull-to-refresh wrapper for bottom-tab screens that use [CustomScrollView].
class VcareRefreshScrollView extends StatelessWidget {
  const VcareRefreshScrollView({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.controller,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollController? controller;

  static const ScrollPhysics physics = AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: controller,
        physics: physics,
        slivers: slivers,
      ),
    );
  }
}
