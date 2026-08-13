import 'package:flutter/material.dart';

/// App-wide scroll behavior — dismisses the IME when the user drags a scroll view.
class VcareScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollViewKeyboardDismissBehavior getKeyboardDismissBehavior(
    BuildContext context,
  ) => ScrollViewKeyboardDismissBehavior.onDrag;
}
