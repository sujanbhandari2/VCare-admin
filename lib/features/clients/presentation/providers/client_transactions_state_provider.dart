import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';

import '../../../../shared/utils/network_error_message.dart';

part 'client_transactions_state_provider.g.dart';

@Riverpod(keepAlive: true)
class ClientTransactionsState extends _$ClientTransactionsState
    with PaginatedListNotifierMixin<ClientTransaction> {
  late final String _clientId;

  @override
  LoadableListState<ClientTransaction> build(String clientId) {
    _clientId = clientId;
    return LoadableListState<ClientTransaction>();
  }

  @override
  bool get mounted => ref.mounted;

  @override
  bool resolveForceRefresh() => true;

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientTransaction>>>
  fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) {
    return ref.read(clientRepositoryProvider).fetchTransactions(
      _clientId,
      request,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> reprocessCharge({
    required String transactionId,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final response = await ref
        .read(clientRepositoryProvider)
        .chargeTransaction(transactionId: transactionId);

    await response.when(
      failure: (error) async {
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await refresh();
        onCompleted?.call(true, null);
      },
    );
  }
}
