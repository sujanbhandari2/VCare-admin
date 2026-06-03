import 'package:flutter_template/core/services/network/http_exception.dart';

typedef EitherResponseOrException<T> = NetworkResult<T, HttpException>;

sealed class NetworkResult<S, F> {
  const NetworkResult();

  T when<T>({
    required T Function(S data) success,
    required T Function(F failure) failure,
  });
}

class Success<S, F> extends NetworkResult<S, F> {
  const Success(this.data);

  final S data;

  @override
  T when<T>({
    required T Function(S data) success,
    required T Function(F failure) failure,
  }) {
    return success(data);
  }
}

class Failure<S, F> extends NetworkResult<S, F> {
  const Failure(this.failureValue);

  final F failureValue;

  @override
  T when<T>({
    required T Function(S data) success,
    required T Function(F failure) failure,
  }) {
    return failure(failureValue);
  }
}

extension NetworkResultX<S, F> on NetworkResult<S, F> {
  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Failure<S, F>;

  S? get dataOrNull => when(success: (data) => data, failure: (_) => null);

  F? get failureOrNull =>
      when(success: (_) => null, failure: (failure) => failure);
}

Future<NetworkResult<T, HttpException>> safeNetworkResultCall<T>(
  Future<T> Function() block,
) async {
  try {
    return Success<T, HttpException>(await block());
  } on HttpException catch (error) {
    return Failure<T, HttpException>(error);
  } catch (error) {
    return Failure<T, HttpException>(HttpException.fromException(error));
  }
}

Future<EitherResponseOrException<T>> safeNetworkCall<T>(
  Future<T> Function() block,
) async {
  return safeNetworkResultCall(block);
}
