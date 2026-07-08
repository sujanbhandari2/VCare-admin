import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/network/stale_while_revalidate.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'client_dependents_state_provider.g.dart';

class ClientDependentsStateData {
  const ClientDependentsStateData({
    this.operation = const OperationState<List<ClientDependent>>.idle(),
    this.dependents = const [],
  });

  final OperationState<List<ClientDependent>> operation;
  final List<ClientDependent> dependents;

  bool get fetching => operation.isLoading;

  bool get isRefreshing => operation.isLoading && dependents.isNotEmpty;

  bool get isInitialLoading => operation.isLoading && dependents.isEmpty;

  String? get error => operation.errorMessage;

  ClientDependentsStateData loading() => ClientDependentsStateData(
    operation: OperationState.loading(data: dependents),
    dependents: dependents,
  );

  ClientDependentsStateData success(List<ClientDependent> dependents) =>
      ClientDependentsStateData(
        operation: OperationState.success(dependents),
        dependents: dependents,
      );

  ClientDependentsStateData failure(String? message) => ClientDependentsStateData(
    operation: OperationState.failure(message, data: dependents),
    dependents: dependents,
  );
}

@Riverpod(keepAlive: true)
class ClientDependentsState extends _$ClientDependentsState {
  int _generation = 0;

  @override
  ClientDependentsStateData build(String clientId) =>
      const ClientDependentsStateData();

  Future<void> fetchDependents({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;

    if (ref.mounted) {
      state = state.loading();
    }

    await fetchStaleWhileRevalidate<PaginatedResult<ClientDependent>>(
      isCurrentGeneration: () => ref.mounted && _generation == generation,
      currentData: state.dependents.isEmpty
          ? null
          : PaginatedResult(
              items: state.dependents,
              pagination: PaginationMeta.empty,
            ),
      forceNetwork: forceRefresh,
      fetch: ({required bool forceRefresh}) => ref
          .read(clientRepositoryProvider)
          .fetchDependents(
            clientId,
            const PaginatedListRequest(page: 1, limit: 20),
            cancelToken: cancelToken,
            forceRefresh: forceRefresh,
          ),
      onStaleData: (result) {
        if (!ref.mounted || _generation != generation) return;
        state = state.success(result.items);
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
              state = state.success(result.items);
            }
          },
        );
      },
    );
  }
}
