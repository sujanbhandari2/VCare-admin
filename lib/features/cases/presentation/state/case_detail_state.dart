import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// Presentation state for a single referral case detail screen.
///
/// Mirrors [ClientDetailStateData] naming (notifier owns `CaseDetailState`).
class CaseDetailStateData {
  const CaseDetailStateData({
    this.fetchOperation = const OperationState<ReferralCase?>.idle(),
    this.updateOperation = const OperationState<ReferralCase?>.idle(),
    this.bookmarkOperation = const OperationState<void>.idle(),
    this.cloneOperation = const OperationState<ReferralCase?>.idle(),
    this.data,
  });

  final OperationState<ReferralCase?> fetchOperation;
  final OperationState<ReferralCase?> updateOperation;
  final OperationState<void> bookmarkOperation;
  final OperationState<ReferralCase?> cloneOperation;
  final ReferralCase? data;

  bool get fetching => fetchOperation.isLoading;

  bool get updating => updateOperation.isLoading;

  bool get bookmarking => bookmarkOperation.isLoading;

  bool get cloning => cloneOperation.isLoading;

  bool get isRefreshing => fetchOperation.isLoading && data != null;

  bool get isInitialLoading => fetchOperation.isLoading && data == null;

  bool get hasError =>
      fetchOperation.hasError ||
      updateOperation.hasError ||
      bookmarkOperation.hasError ||
      cloneOperation.hasError;

  String? get error =>
      updateOperation.errorMessage ??
      bookmarkOperation.errorMessage ??
      cloneOperation.errorMessage ??
      fetchOperation.errorMessage;

  CaseDetailStateData copyWith({
    OperationState<ReferralCase?>? fetchOperation,
    OperationState<ReferralCase?>? updateOperation,
    OperationState<void>? bookmarkOperation,
    OperationState<ReferralCase?>? cloneOperation,
    ReferralCase? data,
    bool clearData = false,
  }) {
    return CaseDetailStateData(
      fetchOperation: fetchOperation ?? this.fetchOperation,
      updateOperation: updateOperation ?? this.updateOperation,
      bookmarkOperation: bookmarkOperation ?? this.bookmarkOperation,
      cloneOperation: cloneOperation ?? this.cloneOperation,
      data: clearData ? null : (data ?? this.data),
    );
  }

  CaseDetailStateData loading() => copyWith(
    fetchOperation: OperationState<ReferralCase?>.loading(data: data),
  );

  CaseDetailStateData success(ReferralCase detail) => copyWith(
    fetchOperation: OperationState<ReferralCase?>.success(detail),
    data: detail,
  );

  CaseDetailStateData failure(String? message) => copyWith(
    fetchOperation: OperationState<ReferralCase?>.failure(message, data: data),
  );

  CaseDetailStateData updatingInProgress() => copyWith(
    updateOperation: OperationState<ReferralCase?>.loading(data: data),
  );

  CaseDetailStateData updateSuccess(ReferralCase detail) => copyWith(
    updateOperation: OperationState<ReferralCase?>.success(detail),
    data: detail,
  );

  CaseDetailStateData updateFailure(String? message) => copyWith(
    updateOperation: OperationState<ReferralCase?>.failure(
      message,
      data: data,
    ),
  );

  CaseDetailStateData bookmarkingInProgress() => copyWith(
    bookmarkOperation: const OperationState<void>.loading(),
  );

  CaseDetailStateData bookmarkSuccess() => copyWith(
    bookmarkOperation: const OperationState<void>.success(null),
  );

  CaseDetailStateData bookmarkFailure(String? message) => copyWith(
    bookmarkOperation: OperationState<void>.failure(message),
  );

  CaseDetailStateData cloningInProgress() => copyWith(
    cloneOperation: OperationState<ReferralCase?>.loading(data: data),
  );

  CaseDetailStateData cloneSuccess(ReferralCase detail) => copyWith(
    cloneOperation: OperationState<ReferralCase?>.success(detail),
  );

  CaseDetailStateData cloneFailure(String? message) => copyWith(
    cloneOperation: OperationState<ReferralCase?>.failure(message, data: data),
  );
}
