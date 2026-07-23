import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

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

  Future<void> createCase({
    required String title,
    required String description,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    if (!mounted) return;

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    final response = await ref.read(clientRepositoryProvider).createClientCase(
      clientId: clientId,
      title: trimmedTitle,
      description: description.trim(),
    );

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
