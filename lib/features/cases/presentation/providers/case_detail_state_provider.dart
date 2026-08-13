import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_detail_state.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/network/stale_while_revalidate.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'case_detail_state_provider.g.dart';

/// Family notifier for a single case — mirrors [ClientDetailState] naming.
@Riverpod(keepAlive: true)
class CaseDetailState extends _$CaseDetailState {
  int _generation = 0;

  @override
  CaseDetailStateData build(String caseId) => const CaseDetailStateData();

  Future<void> fetchDetail({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;

    if (ref.mounted) {
      state = state.loading();
    }

    await fetchStaleWhileRevalidate(
      isCurrentGeneration: () => ref.mounted && _generation == generation,
      currentData: state.data,
      forceNetwork: forceRefresh,
      fetch: ({required bool forceRefresh}) => ref
          .read(caseRepositoryProvider)
          .fetchCaseDetail(
            caseId,
            cancelToken: cancelToken,
            forceRefresh: forceRefresh,
          ),
      onStaleData: (detail) {
        if (!ref.mounted || _generation != generation) return;
        final previous = state.data;
        final merged = previous == null
            ? detail
            : mergeReferralCaseDetail(previous, detail);
        state = state.success(merged);
        state = state.loading();
      },
      onFinalResult: (response) {
        response.when(
          failure: (error) {
            if (ref.mounted && _generation == generation) {
              state = state.failure(error.userMessage);
            }
          },
          success: (detail) {
            if (ref.mounted && _generation == generation) {
              final previous = state.data;
              final merged = previous == null
                  ? detail
                  : mergeReferralCaseDetail(previous, detail);
              state = state.success(merged);
            }
          },
        );
      },
    );
  }

  Future<void> updateCase({
    CaseStatus? status,
    String? type,
    CasePriority? priority,
    String? assignedTo,
    bool clearAssignedTo = false,
    CaseAssignee? assignee,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final previous = state.data;
    if (previous == null || state.updating) return;

    final optimistic = previous.copyWith(
      status: status,
      caseType: type != null ? resolveCaseTypeLabel(type) : null,
      priority: priority,
      assignedTo: clearAssignedTo
          ? 'Unassigned'
          : (assignee?.fullName ?? previous.assignedTo),
      assignedToId: clearAssignedTo ? null : (assignedTo ?? previous.assignedToId),
      clearAssignedToId: clearAssignedTo,
    );

    if (ref.mounted) {
      state = state
          .updatingInProgress()
          .copyWith(data: optimistic);
    }

    final response = await ref.read(caseRepositoryProvider).updateCase(
      caseId,
      UpdateCaseBody(
        status: status?.apiValue,
        type: type != null ? mapCaseTypeLabelToApi(type) : null,
        priority: priority?.apiValue,
        assignedTo: assignedTo,
        clearAssignedTo: clearAssignedTo,
      ),
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage).copyWith(
            data: previous,
          );
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (detail) {
        if (ref.mounted) {
          final merged = mergeReferralCaseDetail(previous, detail);
          state = state.updateSuccess(merged);
        }
        onCompleted?.call(true, null);
        // Hydrate nested client/createdBy if the PATCH body was sparse.
        if (!previous.client.hasIdentity ||
            !detail.client.hasIdentity ||
            isMissingCreatedByLabel(detail.createdBy)) {
          fetchDetail(forceRefresh: true);
        }
      },
    );
  }

  Future<void> toggleBookmark({
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final previous = state.data;
    if (previous == null || state.bookmarking) return;

    final nextBookmarked = !previous.isBookmarked;
    if (ref.mounted) {
      state = state
          .bookmarkingInProgress()
          .copyWith(data: previous.copyWith(isBookmarked: nextBookmarked));
    }

    final response = await ref.read(caseRepositoryProvider).setBookmark(
      caseId,
      bookmarked: nextBookmarked,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.bookmarkFailure(error.userMessage).copyWith(
            data: previous,
          );
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) {
        if (ref.mounted) {
          state = state.bookmarkSuccess();
        }
        onCompleted?.call(true, null);
      },
    );
  }

  Future<void> cloneCase({
    String? assignedTo,
    void Function(ReferralCase? cloned, String? error)? onCompleted,
  }) async {
    if (state.cloning) return;

    if (ref.mounted) {
      state = state.cloningInProgress();
    }

    final response = await ref.read(caseRepositoryProvider).cloneCase(
      caseId,
      assignedTo: assignedTo,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.cloneFailure(error.userMessage);
        }
        onCompleted?.call(null, error.userMessage);
      },
      success: (cloned) {
        if (ref.mounted) {
          state = state.cloneSuccess(cloned);
        }
        onCompleted?.call(cloned, null);
      },
    );
  }

  /// Locally updates the header status after a note save (web parity).
  void applyNoteStatus(CaseStatus status) {
    final current = state.data;
    if (current == null || !ref.mounted) return;
    state = state.success(current.copyWith(status: status));
  }
}
