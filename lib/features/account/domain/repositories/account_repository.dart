import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/account/domain/entities/updated_account_user.dart';
import 'package:vcare_admin/features/account/domain/entities/uploaded_account_file.dart';

abstract class AccountRepository {
  /// Updates name/email via `PATCH users/:userId` (web `updateProfile`).
  Future<EitherResponseOrException<UpdatedAccountUser>> updateProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    CancelToken? cancelToken,
  });

  /// Uploads a profile image via `POST files` (web `uploadFiles`).
  Future<EitherResponseOrException<UploadedAccountFile>> uploadProfilePhoto({
    required List<int> bytes,
    required String fileName,
    CancelToken? cancelToken,
  });

  /// Attaches or clears a profile photo via `PATCH users/:userId` `{ profileId }`.
  /// Pass [profileId] `null` to clear (web `useUpdateProfilePhotoMutation`).
  Future<EitherResponseOrException<UpdatedAccountUser>> updateProfilePhoto({
    required String userId,
    required String? profileId,
    CancelToken? cancelToken,
  });

  /// Changes the signed-in user's password via `POST auth/change-password`.
  Future<EitherResponseOrException<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    CancelToken? cancelToken,
  });
}
