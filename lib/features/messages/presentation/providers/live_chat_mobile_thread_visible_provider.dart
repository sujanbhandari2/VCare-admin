import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Live Chat full-screen mobile conversation thread is open.
///
/// [MainWrapperScreen] clears its shell bottom inset while this is true on the
/// Messages tab so the composer can sit just above the floating nav.
final liveChatMobileThreadVisibleProvider =
    NotifierProvider<LiveChatMobileThreadVisible, bool>(
  LiveChatMobileThreadVisible.new,
);

class LiveChatMobileThreadVisible extends Notifier<bool> {
  @override
  bool build() => false;

  void setVisible(bool visible) {
    if (state == visible) {
      return;
    }
    state = visible;
  }
}
