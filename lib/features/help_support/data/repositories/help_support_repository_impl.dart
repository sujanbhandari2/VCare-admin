import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/help_support/data/mappers/contact_support_result_mapper.dart';
import 'package:vcare_admin/features/help_support/data/models/contact_support_result_model.dart';
import 'package:vcare_admin/features/help_support/domain/entities/contact_support_attachment.dart';
import 'package:vcare_admin/features/help_support/domain/entities/contact_support_result.dart';
import 'package:vcare_admin/features/help_support/domain/repositories/help_support_repository.dart';

/// parity: vcare-agent-app-2.0/src/features/help-support/api/contact-support.api.ts
class HelpSupportRepositoryImpl implements HelpSupportRepository {
  const HelpSupportRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<ContactSupportResult>> submitContactSupport({
    required String message,
    String type = 'support',
    Map<String, Object?>? context,
    List<ContactSupportAttachment> files = const [],
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final trimmedMessage = message.trim();
      if (trimmedMessage.isEmpty) {
        throw HttpException(
          title: 'Missing message',
          message: 'A support message is required',
        );
      }

      final fields = <String, dynamic>{
        'type': type.trim().isEmpty ? 'support' : type.trim(),
        'message': trimmedMessage,
      };

      if (context != null && context.isNotEmpty) {
        fields['context'] = jsonEncode(context);
      }

      final response = await apiClient.post(
        ApiEndpoints.contactSupport,
        MultipartFormData(
          fields: fields,
          files: [
            for (final file in files)
              FormFile.fromPath(
                fieldName: 'files',
                filePath: file.path,
                fileName: file.fileName,
              ),
          ],
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) {
          if (data is Map) {
            return ContactSupportResultModel.fromJson(
              Map<String, dynamic>.from(data),
            );
          }
          return const ContactSupportResultModel(type: 'support');
        },
        dataValidator: (data) {
          if (data is! Map) return false;
          final typeValue = data['type']?.toString().trim() ?? '';
          return typeValue.isNotEmpty;
        },
      );

      return model.toEntity();
    });
  }
}
