import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenericValueNotifier<T> extends Notifier<T> {
  GenericValueNotifier._(this._initialValue);

  final T _initialValue;

  static GenericValueNotifier<T> init<T>(T value) {
    return GenericValueNotifier._(value);
  }

  @override
  T build() => _initialValue;

  void update(T value) {
    state = value;
  }
}
