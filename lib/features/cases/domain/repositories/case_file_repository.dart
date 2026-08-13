import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_file.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';

abstract class CaseFileRepository {
  Future<EitherResponseOrException<List<CaseFile>>> fetchFiles(
    String caseId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<void>> uploadFiles(
    String caseId,
    String clientId, {
    required List<({String fileName, List<int> bytes})> files,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> addFilesFromUrl(
    String caseId,
    String clientId, {
    required List<CaseNotePublicUrl> urls,
    CancelToken? cancelToken,
  });

  /// Files stored on the client profile, offered as attach candidates.
  Future<EitherResponseOrException<List<CaseFile>>> fetchClientProfileFiles(
    String clientId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  /// Copies client profile files onto the case: public links are re-registered
  /// as URLs, stored files are downloaded and re-uploaded.
  Future<EitherResponseOrException<void>> attachProfileFiles(
    String caseId,
    String clientId, {
    required List<CaseFile> files,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> deleteFile(
    String fileId, {
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<List<int>>> downloadFileContent(
    String fileId, {
    bool download = true,
    CancelToken? cancelToken,
  });
}
