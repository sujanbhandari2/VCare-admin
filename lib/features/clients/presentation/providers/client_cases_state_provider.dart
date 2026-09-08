import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';

part 'client_cases_state_provider.g.dart';

@Riverpod(keepAlive: true)
class ClientCasesState extends _$ClientCasesState
    with PaginatedListNotifierMixin<ClientCase> {
  @override
  LoadableListState<ClientCase> build(String clientId) {
    return LoadableListState<ClientCase>();
  }

  @override
  bool get mounted => ref.mounted;

  @override
  int get pageSize => 10;

  @override
  bool resolveForceRefresh() => true;

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientCase>>> fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) {
    return ref.read(clientRepositoryProvider).fetchCases(
      clientId,
      request,
      forceRefresh: forceRefresh,
    );
  }
}
