import 'dart:async';
import 'dart:ui';

class Debouncer {
  Timer? _timer;

  void debounce(Duration duration, VoidCallback taskFunction) {
    resetTimer();
    _timer = Timer(duration, taskFunction);
  }

  void resetTimer() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
