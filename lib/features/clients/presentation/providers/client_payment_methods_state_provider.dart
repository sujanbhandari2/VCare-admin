import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

part 'client_payment_methods_state_provider.g.dart';

class ClientPaymentMethodsStateData {
  const ClientPaymentMethodsStateData({
    this.operation = const OperationState<List<ClientPaymentMethod>>.idle(),
    this.data,
  });

  final OperationState<List<ClientPaymentMethod>> operation;
  final List<ClientPaymentMethod>? data;

  bool get fetching => operation.isLoading;

  String? get error => operation.errorMessage;

  List<ClientPaymentMethod> get methods => data ?? const [];

  ClientPaymentMethodsStateData loading() => ClientPaymentMethodsStateData(
    operation: OperationState.loading(data: data),
    data: data,
  );

  ClientPaymentMethodsStateData success(List<ClientPaymentMethod> methods) =>
      ClientPaymentMethodsStateData(
        operation: OperationState.success(methods),
        data: methods,
      );

  ClientPaymentMethodsStateData failure(String? message) =>
      ClientPaymentMethodsStateData(
        operation: OperationState.failure(message, data: data),
        data: data,
      );
}

@Riverpod(keepAlive: true)
class ClientPaymentMethodsState extends _$ClientPaymentMethodsState {
  @override
  ClientPaymentMethodsStateData build(String clientId) =>
      const ClientPaymentMethodsStateData();

  Future<void> fetchPaymentMethods({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(clientRepositoryProvider)
        .fetchPaymentMethods(clientId, cancelToken: cancelToken);

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.message);
        }
      },
      success: (methods) {
        if (ref.mounted) {
          state = state.success(methods);
        }
      },
    );
  }
}
