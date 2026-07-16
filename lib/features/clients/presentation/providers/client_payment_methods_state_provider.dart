import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/clients/domain/entities/add_client_payment_method_request.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/network/stale_while_revalidate.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'client_payment_methods_state_provider.g.dart';

class ClientPaymentMethodsStateData {
  const ClientPaymentMethodsStateData({
    this.operation = const OperationState<List<ClientPaymentMethod>>.idle(),
    this.data,
  });

  final OperationState<List<ClientPaymentMethod>> operation;
  final List<ClientPaymentMethod>? data;

  bool get fetching => operation.isLoading;

  bool get isRefreshing => operation.isLoading && data != null;

  bool get isInitialLoading => operation.isLoading && data == null;

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
  int _generation = 0;

  @override
  ClientPaymentMethodsStateData build(String clientId) =>
      const ClientPaymentMethodsStateData();

  String get _clientId => clientId;

  Future<void> fetchPaymentMethods({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;

    if (ref.mounted) {
      state = state.loading();
    }

    await fetchStaleWhileRevalidate(
      isCurrentGeneration: () => ref.mounted && _generation == generation,
      currentData: state.data,
      forceNetwork: forceRefresh,
      fetch: ({required bool forceRefresh}) => ref
          .read(clientRepositoryProvider)
          .fetchPaymentMethods(
            _clientId,
            cancelToken: cancelToken,
            forceRefresh: forceRefresh,
          ),
      onStaleData: (methods) {
        if (!ref.mounted || _generation != generation) return;
        state = state.success(methods);
        state = state.loading();
      },
      onFinalResult: (response) {
        response.when(
          failure: (error) {
            if (ref.mounted && _generation == generation) {
              state = state.failure(error.userMessage);
            }
          },
          success: (methods) {
            if (ref.mounted && _generation == generation) {
              state = state.success(methods);
            }
          },
        );
      },
    );
  }

  Future<void> addPaymentMethod({
    required AddClientPaymentMethodRequest request,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final response = await ref
        .read(clientRepositoryProvider)
        .addPaymentMethod(clientId: _clientId, request: request);

    await response.when(
      failure: (error) async {
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await fetchPaymentMethods();
        onCompleted?.call(true, null);
      },
    );
  }

  Future<void> setPrimary({
    required String paymentMethodId,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final response = await ref
        .read(clientRepositoryProvider)
        .setPrimaryPaymentMethod(
          clientId: _clientId,
          paymentMethodId: paymentMethodId,
        );

    await response.when(
      failure: (error) async {
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await fetchPaymentMethods();
        onCompleted?.call(true, null);
      },
    );
  }

  Future<void> remove({
    required String paymentMethodId,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final response = await ref
        .read(clientRepositoryProvider)
        .removePaymentMethod(
          clientId: _clientId,
          paymentMethodId: paymentMethodId,
        );

    await response.when(
      failure: (error) async {
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await fetchPaymentMethods();
        onCompleted?.call(true, null);
      },
    );
  }
}
