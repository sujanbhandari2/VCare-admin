import 'package:flutter/material.dart';

/// Whether the soft keyboard is covering (or about to cover) the bottom of the
/// screen.
///
/// Checks both [MediaQuery.viewInsets] and the platform [View] insets — an
/// ancestor [Scaffold] with `resizeToAvoidBottomInset` may zero MediaQuery
/// insets while the IME is still open.
///
/// Focus alone is intentionally not used: dismissing the IME often leaves an
/// [EditableText] focused, which would keep shell chrome (floating nav)
/// collapsed forever.
bool isSoftKeyboardOpen(BuildContext context) {
  final mediaInsets = MediaQuery.viewInsetsOf(context).bottom;
  if (mediaInsets > 0) {
    return true;
  }
  final view = View.of(context);
  final viewInsets =
      MediaQueryData.fromView(view).viewInsets.bottom;
  return viewInsets > 0;
}
