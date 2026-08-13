import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/account/presentation/providers/account_repository_provider.dart';
import 'package:vcare_admin/features/account/presentation/state/account_password_state.dart';
import 'package:vcare_admin/features/account/utils/account_validators.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'account_password_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AccountPasswordStateNotifier extends _$AccountPasswordStateNotifier {
  @override
  AccountPasswordState build() => const AccountPasswordState();

  void reset() {
    if (ref.mounted) {
      state = state.idle();
    }
  }

  /// Validates and submits password change. Returns true on success.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    CancelToken? cancelToken,
  }) async {
    final currentError =
        AccountValidators.validateCurrentPassword(currentPassword);
    final newError = AccountValidators.validateNewPassword(newPassword);
    final confirmError = AccountValidators.validateConfirmPassword(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    if (currentError != null || newError != null || confirmError != null) {
      if (ref.mounted) {
        state = state.failure(currentError ?? newError ?? confirmError);
      }
      return false;
    }

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref.read(accountRepositoryProvider).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
          cancelToken: cancelToken,
        );

    return response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        return false;
      },
      success: (_) {
        if (ref.mounted) {
          state = state.success();
        }
        return true;
      },
    );
  }
}
