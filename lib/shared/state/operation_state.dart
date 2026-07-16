enum OperationStatus { idle, loading, success, failure }

class OperationState<T> {
  const OperationState({
    this.status = OperationStatus.idle,
    this.data,
    this.errorMessage,
  });

  const OperationState.idle()
    : status = OperationStatus.idle,
      data = null,
      errorMessage = null;

  const OperationState.loading({this.data})
    : status = OperationStatus.loading,
      errorMessage = null;

  const OperationState.success(this.data)
    : status = OperationStatus.success,
      errorMessage = null;

  const OperationState.failure(this.errorMessage, {this.data})
    : status = OperationStatus.failure;

  final OperationStatus status;
  final T? data;
  final String? errorMessage;

  bool get isLoading => status == OperationStatus.loading;
  bool get hasError => status == OperationStatus.failure;
  bool get isSuccess => status == OperationStatus.success;
}
