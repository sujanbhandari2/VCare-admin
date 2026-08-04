import 'package:flutter/material.dart';

/// Shared widths so earnings headers and row values stay aligned.
abstract final class CommissionEarningsColumns {
  static const double saleWidth = 72;
  static const double commissionWidth = 88;
  static const double gap = 8;
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
}

/// Fixed-width amount cell used by headers and values.
class CommissionAmountCell extends StatelessWidget {
  const CommissionAmountCell({
    super.key,
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(alignment: Alignment.centerRight, child: child),
    );
  }
}
