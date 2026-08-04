import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_repository_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'todo_list_state_provider.g.dart';

@Riverpod(keepAlive: true)
class TodoListState extends _$TodoListState
    with PaginatedListNotifierMixin<TodoItem> {
  bool _reprocessing = false;

  @override
  LoadableListState<TodoItem> build() => LoadableListState<TodoItem>();

  @override
  bool get mounted => ref.mounted;

  @override
  bool resolveForceRefresh() => ref.read(networkFetchSessionProvider);

  bool get isReprocessing => _reprocessing;

  @override
  Future<EitherResponseOrException<PaginatedResult<TodoItem>>> fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) {
    return ref
        .read(todoRepositoryProvider)
        .fetchTodos(request, forceRefresh: forceRefresh);
  }

  Future<void> reprocessCharge({
    required String transactionId,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    if (_reprocessing) return;
    _reprocessing = true;

    final response = await ref
        .read(todoRepositoryProvider)
        .chargeTransaction(transactionId: transactionId);

    await response.when(
      failure: (error) async {
        _reprocessing = false;
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await refresh();
        _reprocessing = false;
        onCompleted?.call(true, null);
      },
    );
  }
}
