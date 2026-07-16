import 'package:flutter/material.dart';

/// Marks routes inside [MainWrapperScreen] that receive automatic bottom inset
/// for the floating mobile nav, so per-screen scroll padding does not double up.
class VCareMobileShellScope extends InheritedWidget {
  const VCareMobileShellScope({
    super.key,
    required this.appliesBottomContentInset,
    required super.child,
  });

  final bool appliesBottomContentInset;

  static bool appliesBottomInsetOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<VCareMobileShellScope>()
            ?.appliesBottomContentInset ??
        false;
  }

  @override
  bool updateShouldNotify(VCareMobileShellScope oldWidget) {
    return appliesBottomContentInset != oldWidget.appliesBottomContentInset;
  }
}
