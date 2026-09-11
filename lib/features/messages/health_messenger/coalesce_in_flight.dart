import 'dart:async';

/// Runs [start] at most once at a time and shares that future with callers.
///
/// The in-flight future is stored **before** [start] runs. That matters
/// because `inFlight ??= asyncWork()` assigns too late: [asyncWork] can
/// notify Riverpod listeners before its first `await`, and those listeners
/// would start nested work and overflow the stack.
Future<void> coalesceInFlightFuture({
  required Future<void>? Function() read,
  required void Function(Future<void>? next) write,
  required Future<void> Function() start,
}) {
  final existing = read();
  if (existing != null) {
    return existing;
  }

  final completer = Completer<void>();
  final future = completer.future;
  write(future);

  start()
      .then(completer.complete, onError: completer.completeError)
      .whenComplete(() {
        if (identical(read(), future)) {
          write(null);
        }
      });

  return future;
}
