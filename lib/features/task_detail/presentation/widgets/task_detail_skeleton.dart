import 'package:flutter/material.dart';

import 'package:vcare_admin/shared/widgets/shimmer.dart';

/// Placeholder for the View Task fields while the task loads. The shape mirrors
/// the real field stack so the sheet barely shifts once the data arrives.
class TaskDetailSkeleton extends StatelessWidget {
  const TaskDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      loading: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonField(labelWidth: 46),
          SizedBox(height: 16),
          _SkeletonField(labelWidth: 92, valueHeight: 70),
          SizedBox(height: 16),
          _SkeletonField(labelWidth: 104),
          SizedBox(height: 16),
          _SkeletonField(labelWidth: 96),
          SizedBox(height: 16),
          _SkeletonField(labelWidth: 130),
          SizedBox(height: 16),
          _SkeletonField(labelWidth: 68),
          SizedBox(height: 16),
          _SkeletonField(labelWidth: 60),
        ],
      ),
    );
  }
}

class _SkeletonField extends StatelessWidget {
  const _SkeletonField({required this.labelWidth, this.valueHeight = 44});

  final double labelWidth;
  final double valueHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(context, width: labelWidth, height: 10, radius: 5),
        const SizedBox(height: 7),
        _bar(context, width: double.infinity, height: valueHeight, radius: 12),
      ],
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
