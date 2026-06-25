import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class ClientDetailStateData {
  const ClientDetailStateData({
    this.operation = const OperationState<ClientDetail>.idle(),
    this.data,
  });

  final OperationState<ClientDetail> operation;
  final ClientDetail? data;

  bool get fetching => operation.isLoading;

  String? get error => operation.errorMessage;

  ClientDetailStateData loading() => ClientDetailStateData(
        operation: OperationState.loading(data: data),
        data: data,
      );

  ClientDetailStateData success(ClientDetail detail) => ClientDetailStateData(
        operation: OperationState.success(detail),
        data: detail,
      );

  ClientDetailStateData failure(String? message) => ClientDetailStateData(
        operation: OperationState.failure(message, data: data),
        data: data,
      );
}
