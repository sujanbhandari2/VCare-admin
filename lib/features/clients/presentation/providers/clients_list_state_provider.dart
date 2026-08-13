import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';

part 'clients_list_state_provider.g.dart';

@Riverpod(keepAlive: true)
class ClientsListState extends _$ClientsListState
    with PaginatedListNotifierMixin<ClientListItem> {
  static const String clientTypeExtraKey = 'clientType';

  @override
  LoadableListState<ClientListItem> build() =>
      LoadableListState<ClientListItem>();

  @override
  bool get mounted => ref.mounted;

  @override
  bool resolveForceRefresh() => ref.read(networkFetchSessionProvider);

  ClientListType get clientType {
    final value = state.extras?[clientTypeExtraKey];
    if (value is ClientListType) return value;
    return ClientListType.individual;
  }

  Future<void> setClientType(ClientListType type) async {
    if (clientType == type &&
        (state.items.isNotEmpty || state.isInitialLoading)) {
      return;
    }

    await loadInitial(
      extras: <String, dynamic>{
        ...?state.extras,
        clientTypeExtraKey: type,
        PaginatedListNotifierMixin.searchExtraKey: '',
      },
      forceRefresh: true,
    );
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientListItem>>> fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) {
    return ref.read(clientRepositoryProvider).fetchClients(
      ClientsListRequest(
        page: request.page,
        limit: request.limit,
        search: request.search,
        clientType: clientType,
      ),
      forceRefresh: forceRefresh,
    );
  }
}
