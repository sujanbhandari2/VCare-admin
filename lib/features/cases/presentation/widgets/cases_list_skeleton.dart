import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/shared/widgets/shimmer.dart';

/// Shimmering stand-ins for [CaseRowCard] shown while a cases page is loading.
/// The bar sizes mirror the real card so the list barely shifts once data lands.
class CasesListSkeleton extends StatelessWidget {
  const CasesListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          for (var index = 0; index < itemCount; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _CaseRowCardSkeleton(
              titleWidth: index.isEven ? 132 : 108,
              metaWidth: index.isEven ? 176 : 148,
            ),
          ],
        ],
      ),
    );
  }
}

class _CaseRowCardSkeleton extends StatelessWidget {
  const _CaseRowCardSkeleton({
    required this.titleWidth,
    required this.metaWidth,
  });

  final double titleWidth;
  final double metaWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: VCareColors.cardTint,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: VCareColors.cardTintBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(context, width: 40, height: 40, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(context, width: titleWidth, height: 12, radius: 6),
                      const SizedBox(height: 8),
                      _bar(context, width: 72, height: 10, radius: 5),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _bar(context, width: 18, height: 18, radius: 5),
                const SizedBox(width: 9),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _bar(context, width: 86, height: 22, radius: 11),
                const SizedBox(width: 8),
                _bar(context, width: 74, height: 22, radius: 11),
              ],
            ),
            const SizedBox(height: 12),
            _bar(context, width: metaWidth, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }

  Widget _bar(
    BuildContext context, {
    required double width,
    required double height,
    required double radius,
  }) {
    return Shimmer.loadingContainer(
      context,
      width: width,
      height: height,
      radius: radius,
      opacity: 0.3,
    );
  }
}
