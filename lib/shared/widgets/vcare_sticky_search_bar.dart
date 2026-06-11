import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Sticky search — parity with vcareapp [StickySearchBar].
class VcareStickySearchBar extends StatelessWidget {
  const VcareStickySearchBar({
    super.key,
    required this.controller,
    required this.extent,
    required this.onChanged,
    required this.onFocusChange,
    this.placeholder = 'Search',
  });

  final TextEditingController controller;
  final double extent;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onFocusChange;
  final String placeholder;

  /// 4 + 44 + 16
  static const double expandedHeight = 64;

  /// 6 + 36 + 8
  static const double collapsedHeight = 50;

  static double _lerpExtent(double extent) {
    final range = expandedHeight - collapsedHeight;
    if (range <= 0) return 1;
    return ((extent - collapsedHeight) / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final surface = Theme.of(context).scaffoldBackgroundColor;
    final t = _lerpExtent(extent);
    final fieldHeight = 36 + (44 - 36) * t;
    final topPadding = 6 + (4 - 6) * t;
    final bottomPadding = extent - fieldHeight - topPadding;
    final compact = t < 0.5;
    final iconSize = compact ? 14.0 : 16.0;
    final fontSize = compact ? 14.0 : 15.0;
    final scale = compact ? 0.97 : 1.0;

    return SizedBox(
      height: extent,
      child: ColoredBox(
        color: surface.withValues(alpha: 0.95),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, topPadding, 20, bottomPadding),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: fieldHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: vcare.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: vcare.border),
                ),
                child: Focus(
                  onFocusChange: onFocusChange,
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: TextStyle(fontSize: fontSize),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: TextStyle(
                        fontSize: fontSize,
                        color: vcare.mutedForeground,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: compact ? 8 : 10,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          LucideIcons.search,
                          size: iconSize,
                          color: vcare.mutedForeground,
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: iconSize + 20,
                        minHeight: fieldHeight,
                      ),
                      suffixIcon: ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) {
                          if (controller.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            onPressed: () {
                              controller.clear();
                              onChanged('');
                            },
                            icon: Icon(
                              LucideIcons.x,
                              size: 14,
                              color: vcare.mutedForeground,
                            ),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(28, 28),
                              padding: EdgeInsets.zero,
                            ),
                          );
                        },
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinned header wrapper so the search bar stays above the scrolling list.
class VcareStickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  VcareStickySearchHeaderDelegate({
    required this.scrolled,
    required this.focused,
    required this.controller,
    required this.onChanged,
    required this.onFocusChange,
    this.placeholder = 'Search',
  });

  final bool scrolled;
  final bool focused;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onFocusChange;
  final String placeholder;

  @override
  double get minExtent => focused
      ? VcareStickySearchBar.expandedHeight
      : VcareStickySearchBar.collapsedHeight;

  @override
  double get maxExtent => VcareStickySearchBar.expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    var extent = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);

    if (focused && scrolled) {
      extent = maxExtent;
    }

    return VcareStickySearchBar(
      controller: controller,
      extent: extent,
      onChanged: onChanged,
      onFocusChange: onFocusChange,
      placeholder: placeholder,
    );
  }

  @override
  bool shouldRebuild(covariant VcareStickySearchHeaderDelegate oldDelegate) {
    return scrolled != oldDelegate.scrolled ||
        focused != oldDelegate.focused ||
        controller != oldDelegate.controller ||
        placeholder != oldDelegate.placeholder;
  }
}
