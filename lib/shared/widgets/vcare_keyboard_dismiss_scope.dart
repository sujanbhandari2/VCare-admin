import 'package:flutter/material.dart';

/// Dismisses the soft keyboard when the user taps outside focused inputs.
///
/// Wrap route bodies or sheet content — not individual [TextField]s.
class VcareKeyboardDismissScope extends StatelessWidget {
  const VcareKeyboardDismissScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
