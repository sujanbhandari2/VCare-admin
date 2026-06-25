import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';

part 'commission_history_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CommissionHistoryState extends _$CommissionHistoryState
    with PaginatedListNotifierMixin<CommissionHistoryItem> {
  @override
  LoadableListState<CommissionHistoryItem> build() =>
      LoadableListState<CommissionHistoryItem>();

  @override
  bool get mounted => ref.mounted;

  @override
  Future<EitherResponseOrException<PaginatedResult<CommissionHistoryItem>>>
      fetchPage(
    PaginatedListRequest request,
  ) {
    return ref.read(commissionRepositoryProvider).fetchHistory(request);
  }
}
