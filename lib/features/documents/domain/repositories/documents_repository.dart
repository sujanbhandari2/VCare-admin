import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/documents/domain/entities/agent_file.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

abstract class DocumentsRepository {
  Future<EitherResponseOrException<PaginatedResult<AgentFile>>> fetchFiles(
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<void>> uploadDocument({
    required String fileName,
    required List<int> bytes,
    String? note,
    String? date,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> deleteDocument({
    required String documentId,
    CancelToken? cancelToken,
  });
}
