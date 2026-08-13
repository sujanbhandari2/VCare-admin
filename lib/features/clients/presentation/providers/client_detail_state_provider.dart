import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/features/clients/presentation/state/client_detail_state.dart';
import 'package:vcare_admin/shared/network/stale_while_revalidate.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'client_detail_state_provider.g.dart';

@Riverpod(keepAlive: true)
class ClientDetailState extends _$ClientDetailState {
  int _generation = 0;

  @override
  ClientDetailStateData build(String clientId) => const ClientDetailStateData();

  Future<void> fetchDetail({
    ClientListType clientType = ClientListType.individual,
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
          .fetchClientDetail(
            clientId,
            clientType: clientType,
            cancelToken: cancelToken,
            forceRefresh: forceRefresh,
          ),
      onStaleData: (detail) {
        if (!ref.mounted || _generation != generation) return;
        state = state.success(detail);
        state = state.loading();
      },
      onFinalResult: (response) {
        response.when(
          failure: (error) {
            if (ref.mounted && _generation == generation) {
              state = state.failure(error.userMessage);
            }
          },
          success: (detail) {
            if (ref.mounted && _generation == generation) {
              state = state.success(detail);
            }
          },
        );
      },
    );
  }
}
