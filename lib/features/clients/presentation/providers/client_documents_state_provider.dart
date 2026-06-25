import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';

part 'client_documents_state_provider.g.dart';

@Riverpod(keepAlive: true)
class ClientDocumentsState extends _$ClientDocumentsState
    with PaginatedListNotifierMixin<ClientFile> {
  late final String _clientId;

  @override
  LoadableListState<ClientFile> build(String clientId) {
    _clientId = clientId;
    return LoadableListState<ClientFile>();
  }

  @override
  bool get mounted => ref.mounted;

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientFile>>> fetchPage(
    PaginatedListRequest request,
  ) {
    return ref
        .read(clientRepositoryProvider)
        .fetchDocuments(_clientId, request);
  }
}
