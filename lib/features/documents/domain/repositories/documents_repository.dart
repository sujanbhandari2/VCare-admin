import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/documents/domain/entities/agent_file.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_type_option.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

abstract class DocumentsRepository {
  Future<EitherResponseOrException<PaginatedResult<AgentFile>>> fetchFiles(
    PaginatedListRequest request, {
    required String agentProfileId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<List<DocumentTypeOption>>>
  fetchDocumentTypes({
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<void>> uploadDocument({
    required String fileName,
    required List<int> bytes,
    required String agentProfileId,
    required String documentType,
    String? note,
    String? date,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> renameDocument({
    required String documentId,
    required String name,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<Uint8List>> downloadDocumentContent({
    required String documentId,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> deleteDocument({
    required String documentId,
    CancelToken? cancelToken,
  });
}
