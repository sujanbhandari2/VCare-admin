import 'package:flutter_template/features/profile/domain/entities/user_profile.dart';

import '../../../../shared/state/operation_state.dart';

class UserProfileState {
  const UserProfileState({
    this.fetchOperation = const OperationState<UserProfile>.idle(),
    this.updateOperation = const OperationState<UserProfile>.idle(),
    this.profile,
  });

  final OperationState<UserProfile> fetchOperation;
  final OperationState<UserProfile> updateOperation;
  final UserProfile? profile;

  bool get fetching => fetchOperation.isLoading;

  bool get isUpdating => updateOperation.isLoading;

  String? get error =>
      updateOperation.errorMessage ?? fetchOperation.errorMessage;

  UserProfileState fetchingInProgress() => UserProfileState(
    fetchOperation: OperationState.loading(data: profile),
    updateOperation: updateOperation,
    profile: profile,
  );

  UserProfileState fetchSuccess(UserProfile data) => UserProfileState(
    fetchOperation: OperationState.success(data),
    updateOperation: updateOperation,
    profile: data,
  );

  UserProfileState fetchFailure(String? message) => UserProfileState(
    fetchOperation: OperationState.failure(message, data: profile),
    updateOperation: updateOperation,
    profile: profile,
  );

  UserProfileState updatingInProgress() => UserProfileState(
    fetchOperation: fetchOperation,
    updateOperation: OperationState.loading(data: profile),
    profile: profile,
  );

  UserProfileState updateSuccess(UserProfile data) => UserProfileState(
    fetchOperation: fetchOperation,
    updateOperation: OperationState.success(data),
    profile: data,
  );

  UserProfileState updateFailure(
    String? message, {
    UserProfile? fallbackProfile,
  }) => UserProfileState(
    fetchOperation: fetchOperation,
    updateOperation: OperationState.failure(
      message,
      data: fallbackProfile ?? profile,
    ),
    profile: fallbackProfile ?? profile,
  );
}
