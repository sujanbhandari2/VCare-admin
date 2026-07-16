import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/clients/domain/entities/client_memberships_result.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/network/stale_while_revalidate.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'client_memberships_state_provider.g.dart';

class ClientMembershipsStateData {
  const ClientMembershipsStateData({
    this.operation = const OperationState<ClientMembershipsResult>.idle(),
    this.data,
  });

  final OperationState<ClientMembershipsResult> operation;
  final ClientMembershipsResult? data;

  bool get fetching => operation.isLoading;

  bool get isRefreshing => operation.isLoading && data != null;

  bool get isInitialLoading => operation.isLoading && data == null;

  String? get error => operation.errorMessage;

  ClientMembershipsStateData loading() => ClientMembershipsStateData(
    operation: OperationState.loading(data: data),
    data: data,
  );

  ClientMembershipsStateData success(ClientMembershipsResult result) =>
      ClientMembershipsStateData(
        operation: OperationState.success(result),
        data: result,
      );

  ClientMembershipsStateData failure(String? message) =>
      ClientMembershipsStateData(
        operation: OperationState.failure(message, data: data),
        data: data,
      );
}

@Riverpod(keepAlive: true)
class ClientMembershipsState extends _$ClientMembershipsState {
  int _generation = 0;

  @override
  ClientMembershipsStateData build(String clientId) =>
      const ClientMembershipsStateData();

  Future<void> fetchMemberships({
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
          .fetchClientMemberships(
            clientId,
            cancelToken: cancelToken,
            forceRefresh: forceRefresh,
          ),
      onStaleData: (result) {
        if (!ref.mounted || _generation != generation) return;
        state = state.success(result);
        state = state.loading();
      },
      onFinalResult: (response) {
        response.when(
          failure: (error) {
            if (ref.mounted && _generation == generation) {
              state = state.failure(error.userMessage);
            }
          },
          success: (result) {
            if (ref.mounted && _generation == generation) {
              state = state.success(result);
            }
          },
        );
      },
    );
  }
}
