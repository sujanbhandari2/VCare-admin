import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/domain/repositories/pending_membership_repository.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/providers/pending_membership_repository_provider.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/state/pending_membership_detail_state.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'pending_membership_detail_state_provider.g.dart';

/// Page size for the relevant memberships section — parity with web
/// `useMembershipDrawerSections`.
const int _relevantPageSize = 20;

@Riverpod(keepAlive: true)
class PendingMembershipDetailStateNotifier
    extends _$PendingMembershipDetailStateNotifier {
  @override
  PendingMembershipDetailState build(String membershipId) =>
      const PendingMembershipDetailState();

  PendingMembershipRepository get _repository =>
      ref.read(pendingMembershipRepositoryProvider);

  /// Loads the membership plus both sections. [bootstrap] is the list row the
  /// sheet was opened from, so the header renders before the detail lands.
  Future<void> load({
    PendingMembership? bootstrap,
    bool forceRefresh = true,
  }) async {
    if (ref.mounted) {
      state = state.copyWith(
        detailOperation: OperationState.loading(
          data: state.membership ?? bootstrap,
        ),
      );
    }

    final response = await _repository.fetchMembership(
      membershipId,
      forceRefresh: forceRefresh,
    );

    final membership = response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.copyWith(
            detailOperation: OperationState.failure(
              error.userMessage,
              data: state.membership ?? bootstrap,
            ),
          );
        }
        return bootstrap;
      },
      success: (membership) {
        if (ref.mounted) {
          state = state.copyWith(
            detailOperation: OperationState.success(membership),
          );
        }
        return membership;
      },
    );

    final clientId = membership?.clientId.trim();
    if (clientId == null || clientId.isEmpty) return;

    await Future.wait([
      loadAssociated(clientId: clientId, forceRefresh: forceRefresh),
      loadRelevant(clientId: clientId, forceRefresh: forceRefresh),
    ]);
  }

  Future<void> loadAssociated({
    String? clientId,
    bool forceRefresh = true,
  }) async {
    final resolvedClientId = clientId ?? state.membership?.clientId.trim();
    if (resolvedClientId == null || resolvedClientId.isEmpty) return;

    if (ref.mounted) {
      state = state.copyWith(
        associatedOperation: OperationState.loading(
          data: state.associatedOperation.data,
        ),
      );
    }

    final response = await _repository.fetchAssociatedMemberships(
      resolvedClientId,
      forceRefresh: forceRefresh,
    );

    if (!ref.mounted) return;

    response.when(
      failure: (error) {
        state = state.copyWith(
          associatedOperation: OperationState.failure(
            error.userMessage,
            data: state.associatedOperation.data,
          ),
        );
      },
      success: (result) {
        state = state.copyWith(
          associatedOperation: OperationState.success(result),
        );
      },
    );
  }

  Future<void> loadRelevant({
    String? clientId,
    bool forceRefresh = true,
  }) async {
    final resolvedClientId = clientId ?? state.membership?.clientId.trim();
    if (resolvedClientId == null || resolvedClientId.isEmpty) return;

    if (ref.mounted) {
      state = state.copyWith(
        relevantOperation: OperationState.loading(
          data: state.relevantOperation.data,
        ),
      );
    }

    final response = await _repository.fetchRelevantMemberships(
      resolvedClientId,
      limit: _relevantPageSize,
      forceRefresh: forceRefresh,
    );

    if (!ref.mounted) return;

    response.when(
      failure: (error) {
        state = state.copyWith(
          relevantOperation: OperationState.failure(
            error.userMessage,
            data: state.relevantOperation.data,
          ),
        );
      },
      success: (page) {
        state = state.copyWith(
          relevantOperation: OperationState.success(page.items),
          relevantPage: page.pagination.page,
          relevantTotal: _resolveRelevantTotal(
            loadedCount: page.items.length,
            receivedCount: page.items.length,
            reportedTotal: page.pagination.total,
          ),
        );
      },
    );
  }

  Future<void> loadMoreRelevant() async {
    if (state.loadingMoreRelevant || !state.hasMoreRelevant) return;

    final clientId = state.membership?.clientId.trim();
    if (clientId == null || clientId.isEmpty) return;

    if (ref.mounted) {
      state = state.copyWith(loadingMoreRelevant: true);
    }

    final response = await _repository.fetchRelevantMemberships(
      clientId,
      page: state.relevantPage + 1,
      limit: _relevantPageSize,
    );

    if (!ref.mounted) return;

    response.when(
      failure: (_) {
        state = state.copyWith(loadingMoreRelevant: false);
      },
      success: (page) {
        final existingIds = state.relevantMemberships
            .map((membership) => membership.id)
            .toSet();
        final merged = [
          ...state.relevantMemberships,
          ...page.items.where((membership) => existingIds.add(membership.id)),
        ];

        state = state.copyWith(
          relevantOperation: OperationState.success(merged),
          relevantPage: page.pagination.page,
          relevantTotal: _resolveRelevantTotal(
            loadedCount: merged.length,
            receivedCount: page.items.length,
            reportedTotal: page.pagination.total,
          ),
          loadingMoreRelevant: false,
        );
      },
    );
  }

  /// A short page means there is nothing left to load, so the total is pinned
  /// to what is on screen; a full page with an understated total keeps paging.
  int _resolveRelevantTotal({
    required int loadedCount,
    required int receivedCount,
    required int reportedTotal,
  }) {
    if (receivedCount < _relevantPageSize) return loadedCount;
    return reportedTotal > loadedCount ? reportedTotal : loadedCount + 1;
  }

  /// Declines the membership with a required reason —
  /// `POST /enrollments/cancel`.
  Future<bool> decline({
    required String note,
    void Function(String? message)? onError,
  }) async {
    if (state.declining) return false;

    if (ref.mounted) {
      state = state.copyWith(
        declineOperation: const OperationState<PendingMembership>.loading(),
      );
    }

    final response = await _repository.declineMembership(
      membershipId: membershipId,
      note: note,
    );

    return response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.copyWith(
            declineOperation: OperationState.failure(error.userMessage),
          );
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (membership) {
        if (ref.mounted) {
          state = state.copyWith(
            declineOperation: OperationState.success(membership),
            detailOperation: OperationState.success(membership),
          );
        }
        return true;
      },
    );
  }
}
