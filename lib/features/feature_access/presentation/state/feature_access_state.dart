import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class FeatureAccessState {
  const FeatureAccessState({
    this.operation = const OperationState<FeatureAccess>.idle(),
  });

  final OperationState<FeatureAccess> operation;

  bool get fetching =>
      operation.status == OperationStatus.idle || operation.isLoading;

  bool get hasError => operation.hasError;

  String? get error => operation.errorMessage;

  FeatureAccess? get data => operation.data;

  bool get isResolved => operation.isSuccess && data != null;

  bool get caseManagementEnabled => data?.caseManagement ?? false;

  bool get healthChatEnabled => data?.healthChat ?? false;

  bool get membershipEnabled => data?.membership ?? false;

  FeatureAccessState loading() =>
      FeatureAccessState(operation: OperationState.loading(data: data));

  FeatureAccessState success(FeatureAccess value) =>
      FeatureAccessState(operation: OperationState.success(value));

  FeatureAccessState failure(String? message) => FeatureAccessState(
        operation: OperationState.failure(message, data: data),
      );

  FeatureAccessState reset() => const FeatureAccessState();
}
