import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_note_repository.dart';

class FakeCaseNoteRepository implements CaseNoteRepository {
  EitherResponseOrException<List<CaseNote>> fetchNotesResult = const Success(
    [],
  );

  var fetchNotesCount = 0;
  var lastForceRefresh = false;

  @override
  Future<EitherResponseOrException<List<CaseNote>>> fetchNotes(
    String caseId, {
    String? currentUserId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    fetchNotesCount++;
    lastForceRefresh = forceRefresh;
    return fetchNotesResult;
  }

  @override
  Future<EitherResponseOrException<CaseNote>> createNote(
    String caseId, {
    required String note,
    CaseStatus? status,
    String? accessType,
    String? currentUserId,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EitherResponseOrException<CaseNote>> updateNote(
    String caseId,
    String noteId, {
    String? note,
    CaseStatus? status,
    String? accessType,
    String? currentUserId,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EitherResponseOrException<void>> deleteNote(
    String caseId,
    String noteId, {
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EitherResponseOrException<List<CaseNoteTagUser>>> fetchTagUsers(
    String caseId, {
    String? search,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EitherResponseOrException<void>> uploadNoteAttachments(
    String caseId,
    String noteId, {
    List<({String fileName, List<int> bytes})> files = const [],
    List<CaseNotePublicUrl> publicUrls = const [],
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError();
  }
}
