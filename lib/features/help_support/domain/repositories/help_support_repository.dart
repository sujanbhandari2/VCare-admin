import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/help_support/domain/entities/contact_support_attachment.dart';
import 'package:vcare_admin/features/help_support/domain/entities/contact_support_result.dart';

abstract class HelpSupportRepository {
  Future<EitherResponseOrException<ContactSupportResult>> submitContactSupport({
    required String message,
    String type = 'support',
    Map<String, Object?>? context,
    List<ContactSupportAttachment> files = const [],
    CancelToken? cancelToken,
  });
}
