import 'package:flutter_template/shared/state/operation_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OperationState', () {
    test('idle defaults with no data and no error', () {
      const state = OperationState<String>.idle();

      expect(state.status, OperationStatus.idle);
      expect(state.data, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
      expect(state.isSuccess, isFalse);
    });

    test('loading/success/failure expose expected flags', () {
      const loading = OperationState<String>.loading();
      const success = OperationState<String>.success('ok');
      const failure = OperationState<String>.failure('boom');

      expect(loading.isLoading, isTrue);
      expect(success.isSuccess, isTrue);
      expect(success.data, 'ok');
      expect(failure.hasError, isTrue);
      expect(failure.errorMessage, 'boom');
    });
  });
}
