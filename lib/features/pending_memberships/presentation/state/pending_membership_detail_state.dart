import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// State for the membership review sheet — detail plus the associated and
/// relevant membership sections.
class PendingMembershipDetailState {
  const PendingMembershipDetailState({
    this.detailOperation = const OperationState<PendingMembership>.idle(),
    this.associatedOperation =
        const OperationState<MembershipAssociatedResult>.idle(),
    this.relevantOperation =
        const OperationState<List<PendingMembership>>.idle(),
    this.declineOperation = const OperationState<PendingMembership>.idle(),
    this.relevantPage = 0,
    this.relevantTotal = 0,
    this.loadingMoreRelevant = false,
  });

  final OperationState<PendingMembership> detailOperation;
  final OperationState<MembershipAssociatedResult> associatedOperation;
  final OperationState<List<PendingMembership>> relevantOperation;
  final OperationState<PendingMembership> declineOperation;
  final int relevantPage;
  final int relevantTotal;
  final bool loadingMoreRelevant;

  PendingMembership? get membership => detailOperation.data;

  bool get isInitialLoading => detailOperation.isLoading && membership == null;
  bool get isRefreshing => detailOperation.isLoading && membership != null;
  bool get hasDetailError => detailOperation.hasError && membership == null;
  String? get detailError => detailOperation.errorMessage;

  List<PendingMembership> get associatedMemberships =>
      associatedOperation.data?.memberships ?? const [];

  bool get associatedLoading =>
      associatedOperation.isLoading && associatedOperation.data == null;
  bool get associatedHasError =>
      associatedOperation.hasError && associatedOperation.data == null;

  List<PendingMembership> get relevantMemberships =>
      relevantOperation.data ?? const [];

  bool get relevantLoading =>
      relevantOperation.isLoading && relevantOperation.data == null;
  bool get relevantHasError =>
      relevantOperation.hasError && relevantOperation.data == null;

  bool get hasMoreRelevant => relevantMemberships.length < relevantTotal;

  int get remainingRelevantCount {
    final remaining = relevantTotal - relevantMemberships.length;
    return remaining > 0 ? remaining : 0;
  }

  bool get declining => declineOperation.isLoading;

  PendingMembershipDetailState copyWith({
    OperationState<PendingMembership>? detailOperation,
    OperationState<MembershipAssociatedResult>? associatedOperation,
    OperationState<List<PendingMembership>>? relevantOperation,
    OperationState<PendingMembership>? declineOperation,
    int? relevantPage,
    int? relevantTotal,
    bool? loadingMoreRelevant,
  }) {
    return PendingMembershipDetailState(
      detailOperation: detailOperation ?? this.detailOperation,
      associatedOperation: associatedOperation ?? this.associatedOperation,
      relevantOperation: relevantOperation ?? this.relevantOperation,
      declineOperation: declineOperation ?? this.declineOperation,
      relevantPage: relevantPage ?? this.relevantPage,
      relevantTotal: relevantTotal ?? this.relevantTotal,
      loadingMoreRelevant: loadingMoreRelevant ?? this.loadingMoreRelevant,
    );
  }
}
