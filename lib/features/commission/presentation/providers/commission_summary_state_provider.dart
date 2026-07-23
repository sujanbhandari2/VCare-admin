import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/features/commission/presentation/providers/commission_repository_provider.dart';
import 'package:vcare_admin/features/commission/presentation/state/commission_summary_state.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'commission_summary_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CommissionSummaryStateNotifier extends _$CommissionSummaryStateNotifier {
  CommissionFilter _filter = CommissionFilter.all;

  CommissionFilter get filter => _filter;

  @override
  CommissionSummaryState build() => const CommissionSummaryState();

  Future<void> setFilter(CommissionFilter filter) async {
    if (_filter == filter) return;
    _filter = filter;
    await fetchSummary(forceRefresh: true);
  }

  Future<void> fetchSummary({
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(CommissionSummary? summary)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(commissionRepositoryProvider)
        .fetchSummary(
          status: _filter.apiStatus,
          agencyGroupId: _resolveAgencyGroupId(),
          forceRefresh: forceRefresh,
          cancelToken: cancelToken,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (summary) {
        if (ref.mounted) {
          state = state.success(summary);
        }
        onCompleted?.call(summary);
      },
    );
  }

  String? _resolveAgencyGroupId() {
    final id = ref.read(localProfileStateProvider).agencyGroupId?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }
}
