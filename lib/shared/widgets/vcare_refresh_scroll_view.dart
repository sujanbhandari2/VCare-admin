import 'package:flutter/material.dart';

import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Pull-to-refresh wrapper for bottom-tab screens that use [CustomScrollView].
class VcareRefreshScrollView extends StatelessWidget {
  const VcareRefreshScrollView({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.controller,
    this.padForMobileBottomNav = false,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollController? controller;
  final bool padForMobileBottomNav;

  static const ScrollPhysics physics = AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  @override
  Widget build(BuildContext context) {
    final effectiveSlivers = padForMobileBottomNav
        ? [
            ...slivers,
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: context.mobileShellBottomContentPadding,
              ),
            ),
          ]
        : slivers;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: controller,
        physics: physics,
        slivers: effectiveSlivers,
      ),
    );
  }
}
