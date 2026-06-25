import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/clients/domain/entities/client_memberships_result.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

part 'client_memberships_state_provider.g.dart';

class ClientMembershipsStateData {
  const ClientMembershipsStateData({
    this.operation = const OperationState<ClientMembershipsResult>.idle(),
    this.data,
  });

  final OperationState<ClientMembershipsResult> operation;
  final ClientMembershipsResult? data;

  bool get fetching => operation.isLoading;

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
  @override
  ClientMembershipsStateData build(String clientId) =>
      const ClientMembershipsStateData();

  Future<void> fetchMemberships({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(clientRepositoryProvider)
        .fetchClientMemberships(clientId, cancelToken: cancelToken);

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.message);
        }
      },
      success: (result) {
        if (ref.mounted) {
          state = state.success(result);
        }
      },
    );
  }
}
