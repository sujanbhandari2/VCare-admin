import 'package:vcare_admin/features/find_care/domain/entities/current_location_result.dart';
import 'package:vcare_admin/features/find_care/domain/entities/search_location.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class FindCareCurrentLocationState {
  const FindCareCurrentLocationState({
    this.operation = const OperationState<SearchLocation>.idle(),
    this.autoPromptCompleted = false,
    this.lastFailureReason,
  });

  final OperationState<SearchLocation> operation;
  final bool autoPromptCompleted;
  final CurrentLocationFailureReason? lastFailureReason;

  bool get detecting => operation.isLoading;

  bool get hasError => operation.hasError;

  String? get error => operation.errorMessage;

  SearchLocation? get data => operation.data;

  FindCareCurrentLocationState loading() => FindCareCurrentLocationState(
    operation: OperationState.loading(data: data),
    autoPromptCompleted: autoPromptCompleted,
    lastFailureReason: null,
  );

  FindCareCurrentLocationState success(SearchLocation location) =>
      FindCareCurrentLocationState(
        operation: OperationState.success(location),
        autoPromptCompleted: autoPromptCompleted,
        lastFailureReason: null,
      );

  FindCareCurrentLocationState failure({
    required String message,
    CurrentLocationFailureReason? reason,
  }) => FindCareCurrentLocationState(
    operation: OperationState.failure(message, data: data),
    autoPromptCompleted: autoPromptCompleted,
    lastFailureReason: reason,
  );

  FindCareCurrentLocationState copyWith({
    OperationState<SearchLocation>? operation,
    bool? autoPromptCompleted,
    CurrentLocationFailureReason? lastFailureReason,
    bool clearLastFailureReason = false,
  }) {
    return FindCareCurrentLocationState(
      operation: operation ?? this.operation,
      autoPromptCompleted: autoPromptCompleted ?? this.autoPromptCompleted,
      lastFailureReason: clearLastFailureReason
          ? null
          : (lastFailureReason ?? this.lastFailureReason),
    );
  }
}
