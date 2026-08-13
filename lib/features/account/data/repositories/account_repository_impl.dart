import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/account/data/mappers/account_mapper.dart';
import 'package:vcare_admin/features/account/data/models/updated_account_user_model.dart';
import 'package:vcare_admin/features/account/domain/entities/updated_account_user.dart';
import 'package:vcare_admin/features/account/domain/entities/uploaded_account_file.dart';
import 'package:vcare_admin/features/account/domain/repositories/account_repository.dart';
import 'package:vcare_admin/features/documents/data/models/agent_file_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<UpdatedAccountUser>> updateProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.userById(userId),
        JsonRequestBody({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
        }),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      return _parseUpdatedUser(response);
    });
  }

  @override
  Future<EitherResponseOrException<UploadedAccountFile>> uploadProfilePhoto({
    required List<int> bytes,
    required String fileName,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.files,
        MultipartFormData(
          files: [
            FormFile.fromBytes(
              fieldName: 'files',
              bytes: bytes,
              fileName: fileName,
            ),
          ],
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final uploaded = ResponseValidator.parse(
        response,
        (data) {
          if (data is! List || data.isEmpty) {
            return null;
          }

          for (final entry in data) {
            if (entry is! Map) continue;
            final model = AgentFileModel.fromJson(
              Map<String, dynamic>.from(entry),
            );
            final id = model.id.trim();
            if (id.isEmpty) continue;
            final url = model.url?.trim() ?? model.previewLink?.trim();
            return UploadedAccountFile(
              id: id,
              url: (url == null || url.isEmpty) ? null : url,
            );
          }

          return null;
        },
        dataValidator: (data) => data is List,
      );

      if (uploaded == null) {
        throw HttpException(
          title: 'Invalid Response',
          message: 'Uploaded file id was missing from the response.',
          statusCode: response.statusCode,
          requestMethod: response.requestOptions.method,
          requestUri: response.requestOptions.uri,
          responseData: response.data,
        );
      }

      return uploaded;
    });
  }

  @override
  Future<EitherResponseOrException<UpdatedAccountUser>> updateProfilePhoto({
    required String userId,
    required String? profileId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.userById(userId),
        JsonRequestBody({'profileId': profileId}),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      return _parseUpdatedUser(response);
    });
  }

  @override
  Future<EitherResponseOrException<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.authChangePassword,
        JsonRequestBody({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  UpdatedAccountUser _parseUpdatedUser(Response<dynamic> response) {
    final model = ResponseValidator.parse(
      response,
      (data) => UpdatedAccountUserModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
      dataValidator: (data) => data is Map && data['id'] != null,
    );

    return model.toEntity();
  }
}
