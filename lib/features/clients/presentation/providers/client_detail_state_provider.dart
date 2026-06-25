import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/features/clients/presentation/state/client_detail_state.dart';

part 'client_detail_state_provider.g.dart';

@Riverpod(keepAlive: true)
class ClientDetailState extends _$ClientDetailState {
  @override
  ClientDetailStateData build(String clientId) => const ClientDetailStateData();

  Future<void> fetchDetail({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref.read(clientRepositoryProvider).fetchClientDetail(
          clientId,
          cancelToken: cancelToken,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.message);
        }
      },
      success: (detail) {
        if (ref.mounted) {
          state = state.success(detail);
        }
      },
    );
  }
}
